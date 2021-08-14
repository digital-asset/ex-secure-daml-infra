import React, { useState } from "react";
import { useAuth0 } from "@auth0/auth0-react";

const Ledger = () => {
  const [showResult, setShowResult] = useState(false);
  const [apiMessage, setApiMessage] = useState("");
  const { getAccessTokenSilently } = useAuth0();

  /*useEffect(() => {
    let id = setInterval(() => {
        callLedgerApi();
    }, 1000);
    return () => clearInterval(id);
  });*/

  const callLedgerApi = async () => {
    try {
      const audienceOptions = {
        audience: 'https://daml.com/ledger-api'
      };
      const token = await getAccessTokenSilently(audienceOptions);
      console.log(token);

      const response = await fetch("/v1/query", {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      console.log(response);

      const responseData = await response.json();

      setShowResult(true);
      setApiMessage(responseData);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <>
      <h1>Ledger API</h1>
      <button onClick={callLedgerApi}>Fetch all contracts</button>
      {showResult && <p><code>{JSON.stringify(apiMessage, null, 2)}</code></p>}
    </>
  );
};

export default Ledger;
