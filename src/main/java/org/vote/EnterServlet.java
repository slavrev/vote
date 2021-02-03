package org.vote;

import org.json.JSONObject;
import org.vote.model.Voter;
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
public class EnterServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    request.getRequestDispatcher("/enter.jsp").forward(request, response);
  }



  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    String id = request.getParameter("id");
    String passportimagehash = request.getParameter("passportimagehash");
    String sregisteredsecs = request.getParameter("registeredsecs");

    Long registeredsecs = null;
    try {
      registeredsecs = Long.parseLong( sregisteredsecs );
    } catch( Exception e ) {}

    if( id == null || passportimagehash == null || registeredsecs == null ) {

      response.setContentType("text/html");
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      response.getWriter().println("");
      return;
    }

    JSONObject output = new JSONObject();

    try {

      Connection dbConn = null;

      dbConn = DbTools.connect();

      if( request.getRequestURI().equals("/enter") ) {

        if( DbTools.isVoterRegistered( dbConn, id ) ) {

          boolean logined = DbTools.loginVoter( dbConn, id, passportimagehash, registeredsecs );

          if( logined ) {

            if( DbTools.isVoterDataSet( dbConn, id, passportimagehash ) ) {

              output.put("redirect", "targeturl");
            }
            else {

              output.put("redirect", "setvoterdata");
            }
          }
          else { /* wrong passport hash */

            output.put("failed", "wronghash");
          }
        }
        else { /* not registered */

          Voter voter = new Voter();
          voter.id = id;
          voter.passport_image_hash = passportimagehash;
          voter.registeredsecs = registeredsecs;

          DbTools.registerVoter(dbConn, voter);

          Collection<Part> parts = request.getParts();

          Part passportFilePart = request.getPart("passportfile");

          String fileName = id + ".jpg";

          String path = EnterServlet.class.getProtectionDomain().getCodeSource().getLocation().getPath();

          path += "/webapp/files/";

          Files.copy(passportFilePart.getInputStream(), Paths.get(path, "id", fileName), StandardCopyOption.REPLACE_EXISTING);

          output.put("redirect", "setvoterdata");
        }

        request.getSession().setAttribute("voterid", id );
        request.getSession().setAttribute("passportimagehash", passportimagehash );

      }
      else if( request.getRequestURI().equals("/enter/addvoteconflict") ) {

        Voter voter = new Voter();
        voter.id = id;
        voter.passport_image_hash = passportimagehash;
        voter.registeredsecs = registeredsecs;

        String conflictid = DbTools.addVoteConflict(dbConn, voter);

        Collection<Part> parts = request.getParts();

        Part passportFilePart = request.getPart("passportfile");

        String fileName = id + ".jpg";

        String path = EnterServlet.class.getProtectionDomain().getCodeSource().getLocation().getPath();

        path += "/webapp/files/conflicts/voters/"+conflictid;
        String idpath = path + "/id";
        String photopath = path + "/photo";
        String sigpath = path + "/sig";

        File idDir = new File( idpath );
        File photoDir = new File( photopath );
        File sigDir = new File( sigpath );

        if( !idDir.exists() )
          idDir.mkdirs();

        if( !photoDir.exists() )
          photoDir.mkdirs();

        if( !sigDir.exists() )
          sigDir.mkdirs();

        Files.copy(passportFilePart.getInputStream(), Paths.get(path, "id", fileName), StandardCopyOption.REPLACE_EXISTING);

        output.put("redirect", "setvoterdata");
        output.put("voteconflictid", conflictid);

        request.getSession().setAttribute("voteconflictid", conflictid );
        request.getSession().setAttribute("voterid", id );
        request.getSession().setAttribute("passportimagehash", passportimagehash );
      }

      dbConn.close();

      response.setContentType("application/json");
      response.setStatus(HttpServletResponse.SC_OK);
      response.getWriter().println( output.toString() );

    }
    catch( Exception e ) {

      e.printStackTrace();

      response.setContentType("application/json");
      response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
      response.getWriter().println( "" );
    }
  }
}