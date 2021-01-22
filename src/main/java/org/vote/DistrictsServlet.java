package org.vote;

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
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

@MultipartConfig
public class DistrictsServlet extends HttpServlet
{

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    String localityid = request.getParameter("localityid");

    if( localityid == null ) {

      response.setContentType("text/html");
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      response.getWriter().println("");
      return;
    }

    Connection dbConn = null;

    try {
      dbConn = DbTools.connect();

      List<District> districts = DbTools.loadDistricts( dbConn, localityid );

      dbConn.close();

      JSONArray jsonArray = new JSONArray();

      for( District district : districts ) {

        JSONObject jo = new JSONObject();
        jo.put("id", district.id);
        jo.put("name", district.name);

        jsonArray.put( jo );
      }

      response.setContentType("application/json");
      response.setStatus(HttpServletResponse.SC_OK);
      response.getWriter().print( jsonArray.toString() );

    }
    catch(Exception e) {

      e.printStackTrace();

      response.setContentType("text/html");
      response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
      response.getWriter().println("");

    }
  }
}