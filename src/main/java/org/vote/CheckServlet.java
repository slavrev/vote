package org.vote;

import org.vote.model.Campaign;
import org.vote.model.Vote;
import org.vote.tools.DbTools;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.text.SimpleDateFormat;
import java.util.Collection;

@MultipartConfig
public class CheckServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
  {

    if( request.getRequestURI().equals("/check") ) {

      if( request.getSession().getAttribute("checkerid") == null )
        response.sendRedirect("/enterchecker?targeturl=/check");
      else
        request.getRequestDispatcher("/check.jsp").forward(request, response);
    }
    else if( request.getRequestURI().equals("/check/help") ) {

      if( request.getSession().getAttribute("voterid") == null )
        response.sendRedirect("/enter?targeturl=/check/help");
      else
        request.getRequestDispatcher("/helpercheck.jsp").forward(request, response);
    }
  }

  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    if( request.getRequestURI().equals("/check") ) {

      if( request.getSession().getAttribute("checkerid") == null && request.getSession().getAttribute("voterid") == null ) {

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.getWriter().println("");

        return;
      }

      Vote vote = new Vote();

      String who = request.getParameter("who");
      String message = request.getParameter("message");

      vote.voterid = request.getParameter("voterid");
      vote.campaignid = request.getParameter("campaignid");
      vote.state = request.getParameter("state");
      vote.checkerid = request.getParameter("checkerid");

      if( ( who.equals("checker") && request.getSession().getAttribute("checkerid") == null ) ||
        ( who.equals("helper") && request.getSession().getAttribute("voterid") == null )
      ) {

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.getWriter().println("");

        return;
      }

      Connection dbConn = null;

      try {
        dbConn = DbTools.connect();

        if (who.equals("checker")) {

          DbTools.saveVoiceCheckChecker(dbConn, vote, message);
        } else if (who.equals("helper")) {

          DbTools.saveVoiceCheckHelper(dbConn, vote, message);
        }

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
    else if( request.getRequestURI().equals("/check/conflict") ) {


      if( request.getSession().getAttribute("checkerid") == null ) {

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        response.getWriter().println("");

        return;
      }

      Vote vote = new Vote();

      String who = request.getParameter("who");
      String message = request.getParameter("message");

      vote.voterid = request.getParameter("voterid");
      vote.campaignid = request.getParameter("campaignid");
      vote.checkerid = request.getParameter("checkerid");

      String valid = request.getParameter("valid");
      String conflictid = request.getParameter("conflictid");

      if( valid == null || conflictid == null ) {

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        response.getWriter().println("");

        return;
      }

      try {

        Connection dbConn = null;

        dbConn = DbTools.connect();

        DbTools.saveVoteConflictResolve(dbConn, conflictid, vote.voterid, vote.campaignid, valid );

        dbConn.close();

        String path = VoteServlet.class.getProtectionDomain().getCodeSource().getLocation().getPath();

        String path0 = path + "/webapp/files/";
        String path1 = path + "/webapp/files/conflicts/voters/"+conflictid;

        String fileName = vote.voterid + ".jpg";
        String signatureFileName = vote.campaignid + "_" + vote.voterid + ".jpg";

        if( valid.equals("registered") ) {

          deleteConflictDir( path1, fileName, signatureFileName );

          // send email
        }
        else if( valid.equals("conflicted") ) {

          Files.copy( Paths.get(path1, "id", fileName), Paths.get(path0, "id", fileName), StandardCopyOption.REPLACE_EXISTING );
          Files.copy( Paths.get(path1, "photo", fileName), Paths.get(path0, "photo", fileName), StandardCopyOption.REPLACE_EXISTING );
          Files.copy( Paths.get(path1, "sig", signatureFileName), Paths.get(path0, "sig", signatureFileName), StandardCopyOption.REPLACE_EXISTING );

          deleteConflictDir( path1, fileName, signatureFileName );

          // send email

        }
        else if( valid.equals("none") ) {

          deleteConflictDir( path1, fileName, signatureFileName );

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

  void deleteConflictDir( String path, String fileName, String signatureFileName ) throws Exception {

    Files.delete( Paths.get(path, "id", fileName) );
    Files.delete( Paths.get(path, "photo", fileName) );
    Files.delete( Paths.get(path, "sig", signatureFileName) );
    Files.delete( Paths.get(path, "id" ) );
    Files.delete( Paths.get(path, "photo") );
    Files.delete( Paths.get(path, "sig") );
    Files.delete( Paths.get( path ) );
  }
}