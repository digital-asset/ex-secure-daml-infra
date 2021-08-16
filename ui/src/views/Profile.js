import React, { useState, useEffect } from "react";
import { Container, Row, Col } from "reactstrap";

import Highlight from "../components/Highlight";
import Loading from "../components/Loading";
import { useAuth0, withAuthenticationRequired } from "@auth0/auth0-react";

export const ProfileComponent = () => {
  const [apiToken, setApiToken] = useState("");
  const { loading, user, getAccessTokenSilently } = useAuth0();
    useEffect(() => {
        (async () => {
            try {
                const token = await getAccessTokenSilently({
                    audience: 'https://daml.com/ledger-api',
                });
                setApiToken(token);
            } catch (e) {
                console.error(e);
            }
        })();
    }, [getAccessTokenSilently]);

  if (loading || !user) {
      return <Loading/>;
  }

  return (
    <Container className="mb-5">
      <Row className="align-items-center profile-header mb-5 text-center text-md-left">
        <Col md={2}>
          <img
            src={user.picture}
            alt="Profile"
            className="rounded-circle img-fluid profile-picture mb-3 mb-md-0"
          />
        </Col>
        <Col md>
          <h2>{user.name}</h2>
          <p className="lead text-muted">{user.email}</p>
        </Col>
      </Row>
      <Row>
        <Col md>
          <p className="lead text-muted">auth0 user info</p>
        </Col>
      </Row>
      <Row>
        <Highlight>{JSON.stringify(user, null, 2)}</Highlight>
      </Row>
      <Row>
        <Col md>
          <p className="lead text-muted">ledger API authorization header</p>
        </Col>
      </Row>
      <Row>
        <Highlight>{"Bearer " + apiToken}</Highlight>
      </Row>
    </Container>
  );
};

export default withAuthenticationRequired(ProfileComponent, {
  onRedirecting: () => <Loading />,
});
