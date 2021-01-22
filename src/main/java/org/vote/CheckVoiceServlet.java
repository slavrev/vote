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

@MultipartConfig
public class CheckVoiceServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
  {
    if( request.getSession().getAttribute("voterid") == null )
      response.sendRedirect("/enter?targeturl=/checkvoice");
    else
      request.getRequestDispatcher("/checkvoice.jsp").forward(request, response);
  }
}