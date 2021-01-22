package org.vote;

import org.json.JSONArray;
import org.json.JSONObject;
import org.vote.model.Campaign;
import org.vote.tools.DbTools;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;

public class StatisticsServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
  {
    if( request.getRequestURI().equals("/statistics") ) {

      request.getRequestDispatcher("/statistics.jsp").forward(request, response);
    }
    else if( request.getRequestURI().equals("/statistics/total") ||
             request.getRequestURI().equals("/statistics/locality") ||
             request.getRequestURI().equals("/statistics/district") ) {

      try {

        String campaignid = request.getParameter("campaignid");
        String localityid = request.getParameter("localityid");
        String districtid = request.getParameter("districtid");

        Connection dbConn = null;

        dbConn = DbTools.connect();
        Campaign campaign = DbTools.getActiveCampaign( dbConn );

        JSONObject output = new JSONObject();

        if( request.getRequestURI().equals("/statistics/total") ) {

          output.put("votesnumber", DbTools.loadStatisticsVotesTotal( dbConn, campaignid ) );

          JSONArray elementsJsonArray = new JSONArray();

          for( int i=0; i<campaign.data.length; i++ ) {

            String voteElementCode = campaign.data[i][1];
            String voteElementDisplay = campaign.data[i][0];

            JSONObject element = new JSONObject();
            element.put("code", voteElementCode );
            element.put("display", voteElementDisplay );
            element.put("votesnumber", DbTools.loadStatisticsVotesByElementTotal( dbConn, campaignid, voteElementCode ) );

            elementsJsonArray.put( element );
          }

          output.put("elements", elementsJsonArray );
        }
        else if( request.getRequestURI().equals("/statistics/locality") ) {

          output.put("votesnumber", DbTools.loadStatisticsVotesByLocality( dbConn, campaignid, localityid ) );

          JSONArray elementsJsonArray = new JSONArray();

          for( int i=0; i<campaign.data.length; i++ ) {

            String voteElementCode = campaign.data[i][1];
            String voteElementDisplay = campaign.data[i][0];

            JSONObject element = new JSONObject();
            element.put("code", voteElementCode );
            element.put("display", voteElementDisplay );
            element.put("votesnumber", DbTools.loadStatisticsVotesByElementByLocality( dbConn, campaignid, localityid, voteElementCode ) );

            elementsJsonArray.put( element );
          }

          output.put("elements", elementsJsonArray );
        }
        else if( request.getRequestURI().equals("/statistics/district") ) {

          output.put("votesnumber", DbTools.loadStatisticsVotesByDistrict( dbConn, campaignid, localityid, districtid ) );

          JSONArray elementsJsonArray = new JSONArray();

          for( int i=0; i<campaign.data.length; i++ ) {

            String voteElementCode = campaign.data[i][1];
            String voteElementDisplay = campaign.data[i][0];

            JSONObject element = new JSONObject();
            element.put("code", voteElementCode );
            element.put("display", voteElementDisplay );
            element.put("votesnumber", DbTools.loadStatisticsVotesByElementByDistrict( dbConn, campaignid, localityid, districtid, voteElementCode ) );

            elementsJsonArray.put( element );
          }

          output.put("elements", elementsJsonArray );
        }

        dbConn.close();

        response.setContentType("application/json");
        response.setStatus(HttpServletResponse.SC_OK);
        response.getWriter().print( output.toString() );
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