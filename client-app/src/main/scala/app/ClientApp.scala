package app

import java.io.File
import java.io._

import akka.actor.ActorSystem
import com.daml.grpc.adapter.AkkaExecutionSequencerPool
import com.daml.ledger.api.refinements.ApiTypes.ApplicationId
import com.daml.ledger.client.LedgerClient
import com.daml.ledger.client.configuration.CommandClientConfiguration
import com.daml.ledger.client.configuration.LedgerClientConfiguration
import com.daml.ledger.client.configuration.LedgerIdRequirement
import com.typesafe.scalalogging.StrictLogging
import io.grpc.netty.GrpcSslContexts

import java.lang.System._

import scala.concurrent.Await
import scala.concurrent.ExecutionContext
import scala.concurrent.Future
import scala.concurrent.duration._
import io.netty.handler.ssl.{SslProvider, SslContextBuilder}

object ClientApp extends App with StrictLogging {
  private val ledgerHost = args(0)
  private val ledgerPort = args(1).toInt
  private val clientCertPath = args(2)
  private val clientKeyPath = args(3)
  private val caCertPath = args(4)
  private val token = args(5)

  logger.info(s"ledger: $ledgerHost:$ledgerPort")
  logger.info(s"cert: $clientCertPath")
  logger.info(s"key: $clientKeyPath")
  logger.info(s"caCert: $caCertPath")

  val clientCert = new File(clientCertPath)
  val clientKey = new File(clientKeyPath)
  val caCert = new File(caCertPath)

  private val asys: ActorSystem = ActorSystem()
  private val aesf: AkkaExecutionSequencerPool =
    new AkkaExecutionSequencerPool("clientPool")(asys)
  private implicit val ec: ExecutionContext = asys.dispatcher

  private def shutdown(): Unit = {
    logger.info("Shutting down...")
    Await.result(asys.terminate(), 10.seconds)
    ()
  }

  private val applicationId = ApplicationId("TlsDemo")

  val sslContext = GrpcSslContexts
    //.forClient()
    .configure(SslContextBuilder.forClient(), SslProvider.JDK)
    .keyManager(clientCert, clientKey)
    .trustManager(caCert)
    .build()

  private val clientConfig = LedgerClientConfiguration(
    applicationId = ApplicationId.unwrap(applicationId),
    ledgerIdRequirement = LedgerIdRequirement.none,
    commandClient = CommandClientConfiguration.default,
    sslContext = Some(sslContext),
    token = Some(token)
  )

  private val clientF: Future[LedgerClient] =
    LedgerClient.singleHost(ledgerHost, ledgerPort, clientConfig)(ec, aesf)

  val program = for {
    client <- clientF
    version <- client.versionClient.getApiVersion (None)
  } yield {
    logger.info(s"Ledger API Version: $version")
  }

  try {
    Await.result(program, 5.seconds)
  } catch {
    case e: Exception => {
      val sw = new StringWriter
      e.printStackTrace(new PrintWriter(sw))
      logger.error(sw.toString)
      exit(1)
    }
  }

  shutdown()
  exit(0)
}
