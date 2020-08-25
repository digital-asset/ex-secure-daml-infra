import React from "react";

import logo from "../assets/logo.svg";

const Hero = () => (
  <div className="text-center hero my-5">
    <img className="mb-3 app-logo" src={logo} alt="React logo" width="120" />
    <h1 className="mb-4">Authenticating DAML applications with auth0</h1>

    <p className="lead">
      This is a sample application that demonstrates how to set up
      authentication and authorization on a DAML ledger using <a href="https://auth0.com">auth0</a>.
    </p>
  </div>
);

export default Hero;
