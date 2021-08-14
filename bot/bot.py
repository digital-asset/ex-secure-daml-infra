import logging
import datetime
import dazl
import sys
import asyncio
import requests
from dataclasses import dataclass, field

dazl.setup_default_logger(logging.INFO)
logging.basicConfig(filename='bot.log', level=logging.INFO)
EPOCH = datetime.datetime.utcfromtimestamp(0)

@dataclass
class Config:
  party: str
  oauth_token: str
  url: str
  ca_file: str
  cert_file: str
  cert_key_file: str

async def process_contracts(config: Config):
  #--application-name "ex-secure-daml-infra" --url "https://ledger.acme.com:6865" -
  # -cert-key-file "./certs/client/client1.acme.com.key.pem" --cert-file "./certs/client/client1.acme.com.cert.pem"
  # --ca-file "./certs/intermediate/certs/ca-chain.cert.pem" --oauth-client-id "george123456"
  # --oauth-client-secret "ComplexPassphrase!" --oauth-token-uri "https://auth.acme.com:4443/oauth/token"
  # --oauth-ca-file "./certs/intermediate/certs/ca-chain.cert.pem" --oauth-audience "https://daml.com/ledger-api"
  global donateTo

  async with dazl.connect(url=config.url,
                          ca_file=config.ca_file,
                          cert_key_file=config.cert_key_file,
                          cert_file=config.cert_file,
                          oauth_token=config.oauth_token
                          ) as conn:

    async for event in conn.stream("Main:Asset").creates():

      if isinstance(event, dazl.ledger.api_types.CreateEvent):
        logging.info(event.payload)
        if event.payload['owner'] == config.party:
          logging.info("New asset created for {}: {}".format(event.payload['owner'], event.payload['name']))

          if donateTo == None:
            logging.info("No DonorConfig for {}".format(event.payload['owner']))

          if donateTo != None and config.party != donateTo:
            logging.info(config.party + ' is exercising Give on ' + str(event.contract_id))
            await conn.exercise(event.contract_id, 'Give', {'newOwner': donateTo})

async def process_donor(config: Config):
  #--application-name "ex-secure-daml-infra" --url "https://ledger.acme.com:6865" -
  # -cert-key-file "./certs/client/client1.acme.com.key.pem" --cert-file "./certs/client/client1.acme.com.cert.pem"
  # --ca-file "./certs/intermediate/certs/ca-chain.cert.pem" --oauth-client-id "george123456"
  # --oauth-client-secret "ComplexPassphrase!" --oauth-token-uri "https://auth.acme.com:4443/oauth/token"
  # --oauth-ca-file "./certs/intermediate/certs/ca-chain.cert.pem" --oauth-audience "https://daml.com/ledger-api"
  global donateTo

  async with dazl.connect(url=config.url,
                          ca_file=config.ca_file,
                          cert_key_file=config.cert_key_file,
                          cert_file=config.cert_file,
                          oauth_token=config.oauth_token
                          ) as conn:

    async for event in conn.stream("Main:DonorConfig").creates():

      if isinstance(event, dazl.ledger.api_types.CreateEvent):
        logging.info(event.payload)
        if event.payload['owner'] == config.party:
          logging.info("DonorConfig for {}: {}".format(event.payload['owner'], event.payload['donateTo']))

          donateTo = event.payload['donateTo']

async def run_tasks(config: Config):

  task1 = asyncio.create_task(process_contracts(config))
  task2 = asyncio.create_task(process_donor(config))

  await task1
  await task2

donateTo = None

def main(argv):

  logging.info(argv)
  party = argv[0]
  application_id = argv[1]
  url = argv[2]
  ca_file = argv[3]
  cert_file = argv[4]
  cert_key_file = argv[5]
  oauth_client_id = argv[6]
  oauth_client_secret = argv[7]
  oauth_token_uri = argv[8]
  oauth_ca_file = argv[9]
  oauth_audience = argv[10]

  if oauth_audience == None:
    logging.error("ERROR: Need to supply an oAuth audience")
    return

  if oauth_ca_file == "None":
    oauth_ca_file = None

  headers = {"Accept": "application/json"}
  data = {
    "client_id": oauth_client_id,
    "client_secret": oauth_client_secret,
    "audience": oauth_audience,
    "grant_type": "client_credentials",
    "application_id": application_id
  }

  if oauth_token_uri is None:
    logging.error("Token URI not set")
    return

  response = None
  try:
    response = requests.post(
      oauth_token_uri,
      headers=headers,
      data=data,
      auth=None,
      verify=oauth_ca_file,
    )
  except Exception as ex:
    logging.info(ex)
    logging.error("Unable to get token at this time")
    return

  if response.status_code != 200:
    logging.error("ERROR: Unable to retrieve token. Exiting")
    return

  json = response.json()
  oauth_token = json['access_token']

  config = Config(party,oauth_token, url, ca_file, cert_file, cert_key_file)

  logging.info(config.oauth_token)

  asyncio.run(run_tasks(config))

if __name__ == '__main__':
  main(sys.argv[1:])
