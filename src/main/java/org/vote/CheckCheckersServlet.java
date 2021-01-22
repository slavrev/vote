package org.vote;

import org.vote.model.Checker;
import org.vote.model.Vote;
import org.vote.tools.DbTools;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;

@MultipartConfig
public class CheckCheckersServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
  {
    request.getRequestDispatcher("/checkcheckers.jsp").forward(request, response);
  }

  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    String who = request.getParameter("who");
    String checkerid = request.getParameter("checkerid");
    String state = request.getParameter("state");
    String message = request.getParameter("message");
    String conflictid = request.getParameter("conflictid");
    String valid = request.getParameter("valid");

    if( checkerid == null && state == null ) {

      response.setContentType("text/html");
      response.setStatus(HttpServletResponse.SC_FORBIDDEN);
      response.getWriter().println("");

      return;
    }

    if( request.getRequestURI().equals("/admin/checkcheckers") ) {

      Connection dbConn = null;

      try {
        dbConn = DbTools.connect();

        DbTools.saveCheckerCheck( dbConn, checkerid, state, message );

        dbConn.close();

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_OK);
        response.getWriter().println("");

      }
      catch(Exception e) {

        e.printStackTrace();

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        response.getWriter().println("");
      }

    }
    else if( request.getRequestURI().equals("/admin/checkcheckers/conflict") ) {

      try {

        Connection dbConn = null;

        dbConn = DbTools.connect();

        DbTools.saveCheckerConflictResolve(dbConn, conflictid, checkerid, valid );

        dbConn.close();

        String path = VoteServlet.class.getProtectionDomain().getCodeSource().getLocation().getPath();

        String path0 = path + "/webapp/files/checkers/";
        String path1 = path + "/webapp/files/conflicts/checkers/"+conflictid;

        String fileName = checkerid + ".jpg";

        if( valid.equals("registered") ) {

          deleteConflictDir( path1, fileName );

          // send email
        }
        else if( valid.equals("conflicted") ) {

          Files.copy( Paths.get(path1, "id", fileName), Paths.get(path0, "id", fileName), StandardCopyOption.REPLACE_EXISTING );
          Files.copy( Paths.get(path1, "photo", fileName), Paths.get(path0, "photo", fileName), StandardCopyOption.REPLACE_EXISTING );

          deleteConflictDir( path1, fileName );

          // send email

        }
        else if( valid.equals("none") ) {

          deleteConflictDir( path1, fileName );

          // send email
        }

      } catch( Exception e ) {

        e.printStackTrace();

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        response.getWriter().println("");
      }
    }
  }

  void deleteConflictDir( String path, String fileName ) throws Exception {

    Files.delete( Paths.get(path, "id", fileName) );
    Files.delete( Paths.get(path, "photo", fileName) );
    Files.delete( Paths.get(path, "id" ) );
    Files.delete( Paths.get(path, "photo") );
    Files.delete( Paths.get( path ) );
  }
}