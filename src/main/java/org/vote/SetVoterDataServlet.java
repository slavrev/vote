package org.vote;

import org.eclipse.jetty.webapp.WebAppContext;
import org.json.JSONArray;
import org.json.JSONObject;
import org.vote.model.District;
import org.vote.model.Voter;
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
import java.util.Collection;
import java.util.List;

@MultipartConfig
public class SetVoterDataServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

      request.getRequestDispatcher("/setvoterdata.jsp").forward(request, response);
  }

  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    if( request.getRequestURI().equals("/setvoterdata") || request.getRequestURI().equals("/setvoterdata/addvoteconflict") ) {

      if( request.getSession().getAttribute("voterid") == null || request.getSession().getAttribute("passportimagehash") == null ) {

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        response.getWriter().println("");

        return;
      }

      String id = request.getSession().getAttribute("voterid").toString();
      String passportimagehash = request.getSession().getAttribute("passportimagehash").toString();

      String fullname = request.getParameter("fullname");
      String email = request.getParameter("email");
      String localityid = request.getParameter("localityid");
      String districtid = request.getParameter("districtid");
      boolean sendemails = request.getParameter("sendemails").toString().equals("true");

      if( id == null || passportimagehash == null || fullname == null || localityid == null || districtid == null ) {

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        response.getWriter().println("");
        return;
      }

      Connection dbConn = null;

      // request.getSession().getAttribute();

      try {
        dbConn = DbTools.connect();

        Voter voter = new Voter();
        voter.id = id;
        voter.passport_image_hash = passportimagehash;
        voter.fullname = fullname;
        voter.email = email;
        voter.locality_id = localityid;
        voter.district_id = districtid;
        voter.sendemails = sendemails;

        if( request.getRequestURI().equals("/setvoterdata") ) {

          DbTools.setVoterData( dbConn, voter );
        }
        else if( request.getRequestURI().equals("/setvoterdata/addvoteconflict") ) {

          String conflictid = request.getSession().getAttribute("voteconflictid").toString();

          DbTools.addVoterDataToVoteConflict( dbConn, conflictid, voter );
        }

        dbConn.close();

        response.setContentType("application/json");
        response.setStatus(HttpServletResponse.SC_OK);
        response.getWriter().print("");

      }
      catch(Exception e) {

        e.printStackTrace();

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        response.getWriter().println("");
      }
    }
    else if( request.getRequestURI().equals("/setvoterdata/changefullname") ) {

      String id = request.getSession().getAttribute("voterid").toString();
      String fullname = request.getParameter("fullname");

      if( id == null || fullname == null ) {

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        response.getWriter().println("");
        return;
      }

      Connection dbConn = null;

      try {

        dbConn = DbTools.connect();

        DbTools.changeVoterFullname( dbConn, id, fullname );

        dbConn.close();

        response.setContentType("application/json");
        response.setStatus(HttpServletResponse.SC_OK);
        response.getWriter().print("");

      }
      catch(Exception e) {

        e.printStackTrace();

        response.setContentType("text/html");
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        response.getWriter().println("");
      }
    }
  }
}