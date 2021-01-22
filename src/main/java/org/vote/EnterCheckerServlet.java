package org.vote;

import org.vote.model.Checker;
import org.vote.tools.DbTools;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;

@MultipartConfig
public class EnterCheckerServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    request.getRequestDispatcher("/enterchecker.jsp").forward(request, response);
  }

  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    String id = request.getParameter("id");
    String passportimagehash = request.getParameter("passportimagehash");

    if( id == null || passportimagehash == null ) {

      response.setContentType("text/html");
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      response.getWriter().println("");
      return;
    }

    Connection dbConn = null;

    try {

      dbConn = DbTools.connect();

      Checker checker = new Checker();
      checker.id = id;
      checker.passportimagehash = passportimagehash;

      if( DbTools.isCheckerRegistered( dbConn, id ) ) {

        if( DbTools.enterChecker( dbConn, id, passportimagehash ) ) {

          request.getSession().setAttribute("checkerid", id );

          response.setContentType("application/json");
          response.setStatus(HttpServletResponse.SC_OK);
          response.getWriter().println( "" );
        }
        else {

          response.setContentType("application/json");
          response.setStatus(HttpServletResponse.SC_NOT_FOUND);
          response.getWriter().println( "" );
        }
      }
      else {

        response.setContentType("application/json");
        response.setStatus(HttpServletResponse.SC_NOT_FOUND);
        response.getWriter().println( "" );
      }

      dbConn.close();
    }
    catch(Exception e) {

      e.printStackTrace();

      response.setContentType("application/json");
      response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
      response.getWriter().println( "" );
    }
  }
}