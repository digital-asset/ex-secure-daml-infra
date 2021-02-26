import logging
from asyncio import sleep
import uuid
import datetime
import time
import dazl
import dazl.client.config
import sys
import asyncio

from dazl.model.reading import ReadyEvent, ContractCreateEvent

dazl.setup_default_logger(logging.INFO)
logging.basicConfig(filename='bot.log', level=logging.INFO)
EPOCH = datetime.datetime.utcfromtimestamp(0)

def send(party, cid, choice_name, newOwner, name):
  logging.info(party + ' is exercising ' + choice_name + ' on ' + str(cid))
  return dazl.exercise(cid, choice_name, {'newOwner': newOwner})

def init(network: dazl.Network, owner):
  sender_client = network.aio_party(owner)

def register_handler(network: dazl.Network, party):
  party_client = network.aio_party(party)



  @party_client.ledger_ready()
  async def init(event: ReadyEvent):
    cmds = []

    # fix oddity where contracts not showing initially
    await asyncio.sleep(5)

    donateTo = None
    assets = event.acs_find_active('Main:DonorConfig', match=lambda cdata: cdata['owner'] == party)
    if len(assets) == 0:
      logging.info("Initializing DonorConfig for " + party)
      #return dazl.create('Main:DonorConfig', {'owner': party, 'donateTo': 'Alice'})
      await party_client.submit_create('Main:DonorConfig', {'owner': party, 'donateTo': 'Alice'});
      donateTo = 'Alice'

    donor_config = event.acs_find_active('Main:DonorConfig', match=lambda cdata: cdata['owner'] == party)
    for donorCid, donorData in donor_config.items():
      donateTo = donorData['donateTo']
    logging.info("Party: {} is configured to donate to: {}".format(party, donateTo))

    assets = event.acs_find_active('Main:Asset', match=lambda cdata: cdata['owner'] == party)
    for assetCid, assetData in assets.items():
      if party != donateTo:
        cmds.append(send(party, assetCid, 'Give', donateTo, assetData['name']))

    return cmds

  @party_client.ledger_created('Main:Asset')
  async def ping(event: ContractCreateEvent):
    cmds = []

    if event.cdata['owner'] == party:
      logging.info("New asset created for {}: {}".format(event.cdata['owner'], event.cdata['name']))
      #await sleep(1)
      #return send(party, event.cid, 'RespondPong', event.cdata['count'])

    donateTo = None
    donor_config = event.acs_find_active('Main:DonorConfig', match=lambda cdata: cdata['owner'] == party)
    for donorCid, donorData in donor_config.items():
      donateTo = donorData['donateTo']

    logging.info("Party: {} is configured to donate to: {}".format(party, donateTo))

    assets = event.acs_find_active('Main:Asset', match=lambda cdata: cdata['owner'] == party)
    for assetCid, assetData in assets.items():
      if party != donateTo:
        cmds.append(send(party, assetCid, 'Give', donateTo, assetData['name']))

    return cmds

def dazl_main(network):

  network.set_config(
    url="http://ledger.acme.com:6865",
  )
  init(network, 'George')
  register_handler(network, 'George')

def main(argv):

  dazl.run(dazl_main)

if __name__ == '__main__':
  main(sys.argv[1:])
