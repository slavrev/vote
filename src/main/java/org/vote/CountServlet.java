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
import java.util.Collection;

public class CountServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
  {
    if (request.getSession().getAttribute("voterid") == null && request.getSession().getAttribute("checkerid") == null)
      response.sendRedirect("/enter?targeturl=/count");
    else {

      if( request.getRequestURI().equals("/count") ) {

        request.getRequestDispatcher("/count.jsp").forward(request, response);
      }
      else if( request.getRequestURI().equals("/count/load") ) {

        try {

          String campaignid = request.getParameter("campaignid").toString();
          long numberfrom = Long.parseLong( request.getParameter("numberfrom").toString() );

          Connection dbConn = null;

          dbConn = DbTools.connect();

          String output = DbTools.loadVotes( dbConn, campaignid, numberfrom );

          dbConn.close();

          response.setContentType("text/html");
          response.setStatus(HttpServletResponse.SC_OK);
          response.getWriter().print( output );
        }
        catch(Exception e) {

          e.printStackTrace();

          response.setContentType("text/html");
          response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
          response.getWriter().print("");
        }


      }
    }


  }
}