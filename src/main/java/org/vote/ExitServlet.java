package org.vote;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

public class ExitServlet extends HttpServlet
{
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
  {

    request.getSession().removeAttribute("voterid");
    request.getSession().removeAttribute("checkerid");

    request.getSession().removeAttribute("voteconflictid");
    request.getSession().removeAttribute("passportimagehash");

    // request.getRequestDispatcher("/index.jsp").forward(request, response);

    response.sendRedirect(request.getContextPath() + "/");
  }
}