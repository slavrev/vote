package org.vote;

import org.vote.model.Checker;
import org.vote.tools.DbTools;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.util.Collection;

@MultipartConfig
public class RegisterCheckerServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    if( request.getRequestURI().equals("/registerchecker") )
      request.getRequestDispatcher("/registerchecker.jsp").forward(request, response);

    else if( request.getRequestURI().equals("/registerchecker/fix") )
      request.getRequestDispatcher("/registercheckerfix.jsp").forward(request, response);
  }

  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    String id = request.getParameter("id");
    String passportimagehash = request.getParameter("passportimagehash");
    String fullname = request.getParameter("fullname");
    String email = request.getParameter("email");
    String localityid = request.getParameter("localityid");
    String districtid = request.getParameter("districtid");
    boolean sendemails = request.getParameter("sendemails").equals("true");
    String sregisteredsecs = request.getParameter("registeredsecs");

    Long registeredsecs = null;
    try {
      registeredsecs = Long.parseLong( sregisteredsecs );
    } catch( Exception e ) {}


    if( id == null || passportimagehash == null || fullname == null || email == null || localityid == null || districtid == null || registeredsecs == null ) {

      response.setContentType("application/json");
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      response.getWriter().println( "" );

      return;
    }

    Connection dbConn = null;

    Collection<Part> parts = request.getParts();

    Part passportFilePart = request.getPart("passportfile");
    Part photoFilePart = request.getPart("photofile");

    String fileName = id + ".jpg";

    String path = RegisterCheckerServlet.class.getProtectionDomain().getCodeSource().getLocation().getPath();


    try {

      dbConn = DbTools.connect();

      Checker checker = new Checker();
      checker.id = id;
      checker.passportimagehash = passportimagehash;
      checker.registeredsecs = registeredsecs;
      checker.fullname = fullname;
      checker.email = email;
      checker.state = "n";
      checker.message = "";
      checker.localityid = localityid;
      checker.districtid = districtid;
      checker.sendemails = sendemails;
      checker.nchecked = 0;

      if( !DbTools.isCheckerRegistered( dbConn, checker.id ) ) {

        DbTools.registerChecker( dbConn, checker );

        path += "/webapp/files/checkers/";

        Files.copy( passportFilePart.getInputStream(), Paths.get( path,  "id", fileName ), StandardCopyOption.REPLACE_EXISTING );
        Files.copy( photoFilePart.getInputStream(), Paths.get( path, "photo", fileName ), StandardCopyOption.REPLACE_EXISTING );
      }
      else { /* registered */

        if( request.getRequestURI().equals("/registerchecker/fix") ) {

          DbTools.updateChecker( dbConn, checker );

          path += "/webapp/files/checkers/";

          Files.copy( passportFilePart.getInputStream(), Paths.get( path,  "id", fileName ), StandardCopyOption.REPLACE_EXISTING );
          Files.copy( photoFilePart.getInputStream(), Paths.get( path, "photo", fileName ), StandardCopyOption.REPLACE_EXISTING );
        }
        else { /* conflict */

          String conflictid = DbTools.addCheckerConflict( dbConn, checker );

          path += "/webapp/files/conflicts/checkers/"+conflictid;
          String idpath = path + "/id";
          String photopath = path + "/photo";

          File idDir = new File( idpath );
          File photoDir = new File( photopath );

          if( !idDir.exists() )
            idDir.mkdirs();

          if( !photoDir.exists() )
            photoDir.mkdirs();

          Files.copy( passportFilePart.getInputStream(), Paths.get( path,  "id", fileName ), StandardCopyOption.REPLACE_EXISTING );
          Files.copy( photoFilePart.getInputStream(), Paths.get( path, "photo", fileName ), StandardCopyOption.REPLACE_EXISTING );
        }
      }

      dbConn.close();

      request.getSession().setAttribute("checkerid", id );

      response.setContentType("application/json");
      response.setStatus(HttpServletResponse.SC_OK);
      response.getWriter().println( "" );

    }
    catch(Exception e) {

      e.printStackTrace();

      response.setContentType("application/json");
      response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
      response.getWriter().println( "" );
    }

  }
}