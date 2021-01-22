package org.vote;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.net.URLClassLoader;
import javax.servlet.MultipartConfigElement;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.jasper.servlet.JspServlet;
import org.apache.tomcat.util.scan.StandardJarScanner;
import org.eclipse.jetty.apache.jsp.JettyJasperInitializer;
import org.eclipse.jetty.jsp.JettyJspServlet;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.session.DefaultSessionCache;
import org.eclipse.jetty.server.session.FileSessionDataStore;
import org.eclipse.jetty.server.session.SessionCache;
import org.eclipse.jetty.server.session.SessionHandler;
import org.eclipse.jetty.servlet.*;
import org.eclipse.jetty.util.component.AbstractLifeCycle;
import org.eclipse.jetty.webapp.WebAppContext;

public class Main {

  private static final String WEBROOT_INDEX = "/webapp/";

  public static void main(String[] args) throws Exception {

    String path = Main.class.getProtectionDomain().getCodeSource().getLocation().getPath();
    path += "/webapp/files";

    File filesid = new File( path + "/id" );
    File filesphoto = new File( path + "/photo" );
    File filessig = new File( path + "/sig" );

    File filescheckersid = new File( path + "/checkers/id" );
    File filescheckersphoto = new File( path + "/checkers/photo" );

    if( !filesid.exists() )
      filesid.mkdirs();

    if( !filesphoto.exists() )
      filesphoto.mkdirs();

    if( !filessig.exists() )
      filessig.mkdirs();

    if( !filescheckersid.exists() )
      filescheckersid.mkdirs();

    if( !filescheckersphoto.exists() )
      filescheckersphoto.mkdirs();


    URI baseUri = getWebRootResourceUri();

    SessionHandler sessionHandler = new SessionHandler();
    SessionCache sessionCache = new DefaultSessionCache(sessionHandler);
    sessionCache.setSessionDataStore( fileSessionDataStore() );
    sessionHandler.setSessionCache( sessionCache );
    // sessionHandler.setHttpOnly(true);

    // Create Servlet context
    ServletContextHandler servletContextHandler = new ServletContextHandler(ServletContextHandler.SESSIONS);
    servletContextHandler.setContextPath("/");
    servletContextHandler.setResourceBase(baseUri.toASCIIString());
    servletContextHandler.setSessionHandler( sessionHandler );

    ServletHolder voteHolder = new ServletHolder("vote", VoteServlet.class);
    voteHolder.setInitOrder(0);
    voteHolder.getRegistration().setMultipartConfig( new MultipartConfigElement("./tmp") );
    servletContextHandler.addServlet(voteHolder, "/vote");
    servletContextHandler.addServlet(voteHolder, "/vote/addvoteconflict");

    ServletHolder checkVoiceHolder = new ServletHolder("checkvoice", CheckVoiceServlet.class);
    checkVoiceHolder.setInitOrder(0);
    servletContextHandler.addServlet(checkVoiceHolder, "/checkvoice");
    servletContextHandler.addServlet(checkVoiceHolder, "/checkvoice/conflict");

    ServletHolder checkHolder = new ServletHolder("check", CheckServlet.class);
    checkHolder.setInitOrder(0);
    checkHolder.getRegistration().setMultipartConfig( new MultipartConfigElement("./tmp") );
    servletContextHandler.addServlet(checkHolder, "/check");
    servletContextHandler.addServlet(checkHolder, "/check/help");
    servletContextHandler.addServlet(checkHolder, "/check/conflict");

    ServletHolder enterHolder = new ServletHolder("enter", EnterServlet.class);
    enterHolder.setInitOrder(0);
    enterHolder.getRegistration().setMultipartConfig( new MultipartConfigElement("./tmp") );
    servletContextHandler.addServlet(enterHolder, "/enter");
    servletContextHandler.addServlet(enterHolder, "/enter/addvoteconflict");

    ServletHolder enterCheckerHolder = new ServletHolder("enterchecker", EnterCheckerServlet.class);
    enterCheckerHolder.setInitOrder(0);
    enterCheckerHolder.getRegistration().setMultipartConfig( new MultipartConfigElement("./tmp") );
    servletContextHandler.addServlet(enterCheckerHolder, "/enterchecker");

    ServletHolder exitHolder = new ServletHolder("exit", ExitServlet.class);
    exitHolder.setInitOrder(0);
    servletContextHandler.addServlet(exitHolder, "/exit");

    ServletHolder registerCheckerHolder = new ServletHolder("registerchecker", RegisterCheckerServlet.class);
    registerCheckerHolder.setInitOrder(0);
    registerCheckerHolder.getRegistration().setMultipartConfig( new MultipartConfigElement("./tmp") );
    servletContextHandler.addServlet(registerCheckerHolder, "/registerchecker");
    servletContextHandler.addServlet(registerCheckerHolder, "/registerchecker/fix");

    ServletHolder districtsHolder = new ServletHolder("districts", DistrictsServlet.class);
    districtsHolder.setInitOrder(0);
    servletContextHandler.addServlet(districtsHolder, "/getdistricts");

    ServletHolder setVoterDataHolder = new ServletHolder("setvoterdata", SetVoterDataServlet.class);
    setVoterDataHolder.setInitOrder(0);
    setVoterDataHolder.getRegistration().setMultipartConfig( new MultipartConfigElement("./tmp") );
    servletContextHandler.addServlet(setVoterDataHolder, "/setvoterdata");
    servletContextHandler.addServlet(setVoterDataHolder, "/setvoterdata/addvoteconflict");
    servletContextHandler.addServlet(setVoterDataHolder, "/setvoterdata/changefullname");

    ServletHolder checkCheckersHolder = new ServletHolder("checkcheckers", CheckCheckersServlet.class);
    checkCheckersHolder.setInitOrder(0);
    checkCheckersHolder.getRegistration().setMultipartConfig( new MultipartConfigElement("./tmp") );
    servletContextHandler.addServlet(checkCheckersHolder, "/admin/checkcheckers");
    servletContextHandler.addServlet(checkCheckersHolder, "/admin/checkcheckers/conflict");

    ServletHolder statisticsHolder = new ServletHolder("statistics", StatisticsServlet.class);
    statisticsHolder.setInitOrder(0);
    servletContextHandler.addServlet(statisticsHolder, "/statistics");
    servletContextHandler.addServlet(statisticsHolder, "/statistics/total");
    servletContextHandler.addServlet(statisticsHolder, "/statistics/locality");
    servletContextHandler.addServlet(statisticsHolder, "/statistics/district");

    ServletHolder countHolder = new ServletHolder("count", CountServlet.class);
    countHolder.setInitOrder(0);
    servletContextHandler.addServlet(countHolder, "/count");
    servletContextHandler.addServlet(countHolder, "/count/load");

    // Since this is a ServletContextHandler we must manually configure JSP support.
    enableEmbeddedJspSupport(servletContextHandler);


    // Default Servlet (always last, always named "default")
    ServletHolder holderDefault = new ServletHolder("default", DefaultServlet.class);
    holderDefault.setInitParameter("resourceBase", baseUri.toASCIIString());
    holderDefault.setInitParameter("dirAllowed", "false");
    holderDefault.setInitParameter("pathInfoOnly","false");
    // holderDefault.setInitOrder(10);
    servletContextHandler.addServlet(holderDefault, "/");

    // ServletMapping mapping = new ServletMapping();
    // mapping.

    // servletContextHandler.addServlet(VoteServlet.class, "/vote");



    Server server = new Server(8080);

    server.setHandler( servletContextHandler );

    // handler.addServlet(HelloServlet.class, "/hello/*");
    server.start();
    server.join();
  }

  private static URI getWebRootResourceUri() throws FileNotFoundException, URISyntaxException
  {
    URL indexUri = Main.class.getResource(WEBROOT_INDEX);
    if (indexUri == null)
    {
      throw new FileNotFoundException("Unable to find resource " + WEBROOT_INDEX);
    }
    // Points to wherever /webroot/ (the resource) is
    return indexUri.toURI();
  }

  private static void enableEmbeddedJspSupport(ServletContextHandler servletContextHandler) throws IOException
  {
    // Establish Scratch directory for the servlet context (used by JSP compilation)
    File tempDir = new File(System.getProperty("java.io.tmpdir"));
    File scratchDir = new File(tempDir.toString(), "embedded-jetty-jsp");

    if (!scratchDir.exists())
    {
      if (!scratchDir.mkdirs())
      {
        throw new IOException("Unable to create scratch directory: " + scratchDir);
      }
    }
    servletContextHandler.setAttribute("javax.servlet.context.tempdir", scratchDir);

    // Set Classloader of Context to be sane (needed for JSTL)
    // JSP requires a non-System classloader, this simply wraps the
    // embedded System classloader in a way that makes it suitable
    // for JSP to use
    ClassLoader jspClassLoader = new URLClassLoader(new URL[0], Main.class.getClassLoader());
    servletContextHandler.setClassLoader(jspClassLoader);

    // Manually call JettyJasperInitializer on context startup
    servletContextHandler.addBean(new JspStarter(servletContextHandler));

    // Create / Register JSP Servlet (must be named "jsp" per spec)

    ServletHolder holderJsp = new ServletHolder("jsp", JettyJspServlet.class);
    holderJsp.setInitOrder(0);
    holderJsp.setInitParameter("logVerbosityLevel", "DEBUG");
    holderJsp.setInitParameter("fork", "false");
    holderJsp.setInitParameter("xpoweredBy", "false");
    holderJsp.setInitParameter("compilerTargetVM", "1.8");
    holderJsp.setInitParameter("compilerSourceVM", "1.8");
    holderJsp.setInitParameter("keepgenerated", "true");

    servletContextHandler.addServlet(holderJsp, "*.jsp");
  }

  public static class JspStarter extends AbstractLifeCycle implements ServletContextHandler.ServletContainerInitializerCaller
  {
    JettyJasperInitializer sci;
    ServletContextHandler context;

    public JspStarter (ServletContextHandler context)
    {
      this.sci = new JettyJasperInitializer();
      this.context = context;
      this.context.setAttribute("org.apache.tomcat.JarScanner", new StandardJarScanner());
    }

    @Override
    protected void doStart() throws Exception
    {
      ClassLoader old = Thread.currentThread().getContextClassLoader();
      Thread.currentThread().setContextClassLoader(context.getClassLoader());
      try
      {
        sci.onStartup(null, context.getServletContext());
        super.doStart();
      }
      finally
      {
        Thread.currentThread().setContextClassLoader(old);
      }
    }
  }

  static FileSessionDataStore fileSessionDataStore() {
    FileSessionDataStore fileSessionDataStore = new FileSessionDataStore();
    File baseDir = new File(System.getProperty("java.io.tmpdir"));
    File storeDir = new File(baseDir, "jetty-session-store");
    storeDir.mkdir();
    fileSessionDataStore.setStoreDir(storeDir);
    return fileSessionDataStore;
  }
}
