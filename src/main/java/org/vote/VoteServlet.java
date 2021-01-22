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
public class VoteServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
  {
    if( request.getSession().getAttribute("voterid") == null )
      response.sendRedirect("/enter?targeturl=/vote");
    else
      request.getRequestDispatcher("/vote.jsp").forward(request, response);
  }


  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    String campaignid = request.getParameter("campaignid");
    String id = request.getParameter("id");
    String votedata = request.getParameter("votedata");

    Connection dbConn = null;
    Campaign campaign = null;

    String s = "";

    Collection<Part> parts = request.getParts();

    Part photoFilePart = request.getPart("photofile");
    Part signatureFilePart = request.getPart("signaturefile");

    String fileName = id + ".jpg";
    String signatureFileName = campaignid + "_" + id + ".jpg";

    String path = VoteServlet.class.getProtectionDomain().getCodeSource().getLocation().getPath();

    if( campaignid == null || id == null || votedata == null || photoFilePart == null || signatureFilePart == null ) {

      response.setContentType("text/html");
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      response.getWriter().println("");
      return;
    }

    try {

      dbConn = DbTools.connect();
      campaign = DbTools.getActiveCampaign( dbConn );

      if( request.getSession().getAttribute("voteconflictid") == null ) {

        Vote vote = DbTools.getVote( dbConn, id, campaignid );

        if( vote == null || vote.state.equals("-") /* declined */ ) {

          vote = new Vote();

          vote.voterid = id;
          vote.campaignid = campaignid;
          vote.sdata = votedata;

          DbTools.addOrEditVote(dbConn, vote);

          path += "/webapp/files/";

          Files.copy(photoFilePart.getInputStream(), Paths.get(path, "photo", fileName), StandardCopyOption.REPLACE_EXISTING);
          Files.copy(signatureFilePart.getInputStream(), Paths.get(path, "sig", signatureFileName), StandardCopyOption.REPLACE_EXISTING);
        }
        else
          throw new Exception("Wrong vote state.");

     }
      else if( request.getSession().getAttribute("voteconflictid") != null ) {

        String conflictid = request.getSession().getAttribute("voteconflictid").toString();
        String passportimagehash = request.getSession().getAttribute("passportimagehash").toString();

        Vote vote = DbTools.getVoteFromConflicts( dbConn, conflictid, id, campaignid );

        if( vote == null ) {

          vote = new Vote();

          vote.voterid = id;
          vote.campaignid = campaignid;
          vote.sdata = votedata;

          DbTools.addVoteToVoteConflict(dbConn, conflictid, passportimagehash, vote);

          path += "/webapp/files/conflicts/voters/"+conflictid;

          Files.copy(photoFilePart.getInputStream(), Paths.get(path, "photo", fileName), StandardCopyOption.REPLACE_EXISTING);
          Files.copy(signatureFilePart.getInputStream(), Paths.get(path, "sig", signatureFileName), StandardCopyOption.REPLACE_EXISTING);

          request.getSession().removeAttribute("passportimagehash");
        }
        else
          throw new Exception("Wrong vote state.");
      }

      dbConn.close();

      response.setContentType("text/html");
      response.setStatus(HttpServletResponse.SC_OK);
      response.getWriter().println("");

    } catch( Exception e ) {

      e.printStackTrace();

      response.setContentType("text/html");
      response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
      response.getWriter().println("");
    }
  }
}