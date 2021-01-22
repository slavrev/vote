package org.vote.tools;

import org.vote.Settings;
import org.vote.model.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DbTools {

  public static Connection connect() throws Exception {

    String url = String.format("jdbc:postgresql://%s/%s?user=%s&password=%s", Settings.db_address, Settings.db_name, Settings.db_user, Settings.db_password);
    return DriverManager.getConnection(url);
  }

  public static Connection connectToRoot(String db_address, String db_user, String db_password) throws Exception {

    String url = String.format("jdbc:postgresql://%s/postgres?user=%s&password=%s", db_address, db_user, db_password);
    return DriverManager.getConnection(url);
  }

//  public static Connection connectToRoot( String db_address, String db_name ) throws Exception {
//
//    String url = String.format("jdbc:postgresql://%s/%s?user=postgres", db_address, db_name );
//    return DriverManager.getConnection(url);
//  }


  public static String selectDbVersion(Connection dbConn) {

    String query = "SELECT version()";

    try (Statement st = dbConn.createStatement();
         ResultSet rs = st.executeQuery(query)) {

      // rs.

      while (rs.next()) {
        //rs.get
        String dbVersion = rs.getString(1);
        //log.info("Database version: " + dbVersion);

        return dbVersion;
      }
    } catch (SQLException e) {

      //log.error("", e);
      return null;
    }

    return null;
  }

  public static Campaign getActiveCampaign( Connection dbConn ) throws Exception {

    Campaign campaign = null;

    String query = "select * from campaigns where state = 'active'";

    PreparedStatement st = dbConn.prepareStatement( query );
    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      campaign = new Campaign();

      campaign.id = rs.getString("id");
      campaign.name = rs.getString("name");
      campaign.description = rs.getString("description");
      campaign.created = rs.getTimestamp("created");
      campaign.todate = rs.getTimestamp("todate");
      campaign.type = rs.getString("type");
      campaign.state = rs.getString("state");
      campaign.sdata = rs.getString("data");

      campaign.parseData();
    }

    rs.close();
    st.close();

    return campaign;
  }

  public static boolean isVoterRegistered(Connection dbConn, String id ) throws Exception {

    int votersCount = 0;

    String query = null;

    query = "select 1 from voters where id = ? limit 1";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, id );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {
      votersCount = 1;
    }

    rs.close();
    st.close();

    if( votersCount == 0 )
      return false;
    else
      return true;
  }


  public static boolean loginVoter(Connection dbConn, String idoremail, String passportimagehash ) throws Exception {

    int votersCount = 0;

    String id = null;
    String email = null;

    String query = null;

    if( idoremail.contains("@") )
      query = "select 1 from voters where email = ? and passportimagehash = ? limit 1";
    else
      query = "select 1 from voters where id = ? and passportimagehash = ? limit 1";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, idoremail );
    st.setString(2, passportimagehash );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {
      votersCount = 1;
    }

    rs.close();
    st.close();

    if( votersCount == 0 )
      return false;
    else
      return true;
  }

  public static boolean isCheckerRegistered(Connection dbConn, String id ) throws Exception {

    int votersCount = 0;

    String query = null;

    query = "select 1 from checkers where id = ? limit 1";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, id );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {
      votersCount = 1;
    }

    rs.close();
    st.close();

    if( votersCount == 0 )
      return false;
    else
      return true;
  }

  public static boolean enterChecker(Connection dbConn, String idoremail, String passportimagehash ) throws Exception {

    int checkersCount = 0;

    String id = null;
    String email = null;

    String query = null;

    if( idoremail.contains("@") )
      query = "select count(*) from checkers where email = ? and passportimagehash = ?";
    else
      query = "select count(*) from checkers where id = ? and passportimagehash = ?";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, idoremail );
    st.setString(2, passportimagehash );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {
      checkersCount = rs.getInt("count");
    }

    rs.close();
    st.close();

    if( checkersCount == 0 )
      return false;
    else
      return true;
  }

  public static boolean isVoterDataSet( Connection dbConn, String id, String passportimagehash ) throws Exception {

    int count = 0;

    String query = "select count(*) from voters where id = ? and passportimagehash = ? and ( fullname is not null and localityid is not null and districtid is not null)";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, id );
    st.setString(2, passportimagehash );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {
      count = rs.getInt("count");
    }

    rs.close();
    st.close();

    if( count == 1 )
      return true;
    else
      return false;
  }

  public static void registerVoter( Connection dbConn, Voter voter ) throws Exception {

    String query = "insert into voters(id, passportimagehash) values(?, ?)";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, voter.id );
    st.setString(2, voter.passport_image_hash );

    st.executeUpdate();

    st.close();
  }

  public static String addVoteConflict( Connection dbConn, Voter voter ) throws Exception {

    String id = null;

    String query = "select * from addVoteConflict( ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, voter.id );
    st.setString(2, voter.passport_image_hash );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      id = rs.getString(1);
    }

    rs.close();
    st.close();

    return id;
  }

  public static String addCheckerConflict( Connection dbConn, Checker checker ) throws Exception {

    String id = null;

    String query = "select * from addCheckerConflict( ?, ?, ?, ?, ?, ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, checker.id );
    st.setString(2, checker.passportimagehash);
    st.setString(3, checker.fullname );
    st.setString(4, checker.email );
    st.setString(5, checker.localityid);
    st.setString(6, checker.districtid);
    st.setBoolean(7, checker.sendemails );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      id = rs.getString(1);
    }

    rs.close();
    st.close();

    return id;
  }

  public static void registerChecker( Connection dbConn, Checker checker ) throws Exception {

    String query = "insert into checkers(id, passportimagehash, fullname, email, state, localityid, districtid, sendemails, nchecked ) values(?, ?, ?, ?, ?, ?, ?, ?, 0)";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, checker.id );
    st.setString(2, checker.passportimagehash);

    st.setString(3, checker.fullname );
    st.setString(4, checker.email );
    st.setString(5, checker.state );
    st.setString(6, checker.localityid);
    st.setString(7, checker.districtid);
    st.setBoolean(8, checker.sendemails );
    // st.setLong(9, checker.nchecked );

    st.executeUpdate();

    st.close();
  }

  public static void updateChecker( Connection dbConn, Checker checker ) throws Exception {

    String query = "update checkers set passportimagehash = ?, fullname = ?, email = ?, state = ?, localityid = ?, districtid = ?, sendemails = ?, nchecked = ?, message = ? where id = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, checker.passportimagehash);
    st.setString(2, checker.fullname );
    st.setString(3, checker.email );
    st.setString(4, checker.state );
    st.setString(5, checker.localityid);
    st.setString(6, checker.districtid);
    st.setBoolean(7, checker.sendemails );
    st.setLong(8, checker.nchecked );
    st.setString(9, checker.message );

    st.setString(10, checker.id );

    st.executeUpdate();

    st.close();
  }

  public static Checker getChecker( Connection dbConn, String id ) throws Exception {

    Checker checker = null;

    String query = "select passportimagehash, fullname, email, localityid, districtid, sendemails, nchecked, message, state, locality, district from getChecker( ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, id);

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      String passportimagehash = rs.getString(1);

      if( passportimagehash != null ) {

        checker = new Checker();

        checker.id = id;
        checker.passportimagehash = rs.getString(1);
        checker.fullname = rs.getString(2);
        checker.email = rs.getString(3);
        checker.localityid = rs.getString(4);
        checker.districtid = rs.getString(5);
        checker.sendemails = rs.getBoolean(6);
        checker.nchecked = rs.getLong(7);
        checker.message = rs.getString(8);
        checker.state = rs.getString(9);

        checker.locality = rs.getString(10);
        checker.district = rs.getString(11);
      }
    }

    rs.close();
    st.close();

    return checker;
  }

  public static Checker getNextCheckerCheck( Connection dbConn ) throws Exception {

    Checker checker = null;

    String query = "select * from getNextCheckerCheck()";

    PreparedStatement st = dbConn.prepareStatement( query );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      String id = rs.getString(1);

      if( id != null ) {

        checker = new Checker();

        checker.id = rs.getString(1);

        checker.fullname = rs.getString(2);
        checker.email = rs.getString(3);
        checker.locality = rs.getString(4);
        checker.district = rs.getString(5);
        checker.conflictid = rs.getString(6 );

        if( checker.conflictid != null )
          checker.conflict = true;
      }
    }

    rs.close();
    st.close();

    return checker;
  }

  public static long getCheckedCheckersCount( Connection dbConn ) throws Exception {

    long nchecked = 0;

    String query = "select count(*) from checkers where state = '+'";

    PreparedStatement st = dbConn.prepareStatement( query );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      nchecked = rs.getLong(1);
    }

    rs.close();
    st.close();

    return nchecked;
  }

  public static long getNotCheckedCheckersCount( Connection dbConn ) throws Exception {

    long nnotchecked = 0;

    String query = "select count(*) from checkers where state = 'n'";

    PreparedStatement st = dbConn.prepareStatement( query );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      nnotchecked = rs.getLong(1);
    }

    rs.close();
    st.close();

    return nnotchecked;
  }

  public static void saveCheckerCheck( Connection dbConn, String checkerid, String state, String message ) throws Exception {

    String query = "update checkers set state = ?, message = ? where id = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, state);
    st.setString(2, message);
    st.setString(3, checkerid);

    st.execute();

    st.close();
  }

  public static List<Locality> loadLocalities(Connection dbConn ) throws Exception {

    List<Locality> localities = new ArrayList<>();

    String query = "select * from localities order by name asc";

    PreparedStatement st = dbConn.prepareStatement( query );
    ResultSet rs = st.executeQuery();

    Locality otherLocality = null;

    while( rs.next() ) {

      Locality locality = new Locality();
      locality.id = rs.getString(1);
      locality.name = rs.getString(2);

      if( locality.name.equals("Другое") )
        otherLocality = locality;
      else
        localities.add( locality );
    }

    localities.add( otherLocality );

    rs.close();
    st.close();

    return localities;
  }

  public static List<District> loadDistricts( Connection dbConn, String localityid ) throws Exception {

    List<District> districts = new ArrayList<>();

    String query = "select id, name from districts where localityid = ? or name = 'Другое' order by name asc";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, localityid );

    ResultSet rs = st.executeQuery();

    District otherDistrict = null;

    while( rs.next() ) {

      District district = new District();
      district.id = rs.getString(1);
      district.name = rs.getString(2);

      if( district.id.equals("xxxx") )
        otherDistrict = district;
      else
        districts.add( district );
    }

    districts.add( otherDistrict );

    rs.close();
    st.close();

    return districts;
  }

  public static void setVoterData( Connection dbConn, Voter voter ) throws Exception {

    String query = "update voters set fullname = ?, email = ?, localityid = ?, districtid = ?, sendemails = ? where id = ? and passportimagehash = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, voter.fullname );
    st.setString(2, voter.email );
    st.setString(3, voter.locality_id );
    st.setString(4, voter.district_id );
    st.setBoolean(5, voter.sendemails );

    st.setString(6, voter.id );
    st.setString(7, voter.passport_image_hash );

    st.executeUpdate();

    st.close();
  }

  public static void changeVoterFullname( Connection dbConn, String voterid, String fullname ) throws Exception {

    String query = "update voters set fullname = ? where id = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, fullname );
    st.setString(2, voterid );

    st.executeUpdate();

    st.close();
  }

  public static void addVoterDataToVoteConflict( Connection dbConn, String conflictid, Voter voter ) throws Exception {

    String query = "select addVoterDataToVoteConflict( ?, ?, ?, ?, ?, ?, ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, conflictid );
    st.setString(2, voter.id );
    st.setString(3, voter.passport_image_hash );

    st.setString(4, voter.fullname );
    st.setString(5, voter.email );
    st.setString(6, voter.locality_id );
    st.setString(7, voter.district_id );
    st.setBoolean(8, voter.sendemails );

    st.execute();

    st.close();
  }

  public static Voter loadVoter( Connection dbConn, String id, String passportimagehash ) throws Exception {

    Voter voter = null;

    String query = "select * from voters where id = ? and passportimagehash = ?";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, id );
    st.setString(2, passportimagehash );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      voter = new Voter();

      voter.id = rs.getString(1);
      voter.passport_image_hash = rs.getString(2);
      voter.fullname = rs.getString(3);
      voter.email = rs.getString(4);
      voter.locality_id = rs.getString(5);
      voter.district_id = rs.getString(6);
      voter.sendemails = rs.getBoolean(7);
    }

    rs.close();
    st.close();

    return voter;
  }

  public static void addOrEditVote(Connection dbConn, Vote vote ) throws Exception {

    String query = "select addOrEditVote( ?, ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, vote.voterid );
    st.setString(2, vote.campaignid);
    st.setString(3, vote.sdata );

    st.execute();

    st.close();
  }

  public static void addVoteToVoteConflict(Connection dbConn, String conflictid, String passportimagehash, Vote vote ) throws Exception {

    String query = "select addVoteToVoteConflict( ?, ?, ?, ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, conflictid );
    st.setString(2, vote.voterid );
    st.setString(3, passportimagehash );

    st.setString(4, vote.campaignid);
    st.setString(5, vote.sdata );

    st.execute();

    st.close();
  }

  public static Vote getVote( Connection dbConn, String voterid, String campaignid ) throws Exception {

    Vote vote = null;

    String query = "select * from getVote( ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, voterid );
    st.setString(2, campaignid );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      if( rs.getString(3) != null ) {

        vote = new Vote();

        vote.voterid = voterid;
        vote.campaignid = campaignid;
        vote.number = rs.getLong(1);
        vote.sent = rs.getTimestamp(2);
        vote.sdata = rs.getString(3);
        vote.state = rs.getString(4);
        vote.checkerid = rs.getString(5);
        vote.sothercheckers = rs.getString(6);
        vote.message = rs.getString(7);
        vote.fullname = rs.getString(8);

        vote.parseData();
        vote.parseOtherCheckers();
      }
    }

    rs.close();
    st.close();

    return vote;
  }

  public static Vote getVoteFromConflicts( Connection dbConn, String conflictid, String voterid, String campaignid ) throws Exception {

    Vote vote = null;

    String query = "select sent, data from votesconflicts where id = ? and voterid = ? and campaignid = ?";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, conflictid );
    st.setString(2, voterid );
    st.setString(3, campaignid );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      vote = new Vote();

      vote.voterid = voterid;
      vote.campaignid = campaignid;
      vote.number = 0L;
      vote.sent = rs.getTimestamp(1);
      vote.sdata = rs.getString(2);
      vote.state = "n";

      vote.parseData();
      vote.parseOtherCheckers();
    }

    rs.close();
    st.close();

    return vote;
  }


  public static String loadVotes( Connection dbConn, String campaignid, long numberfrom ) throws Exception {

    StringBuilder sb = new StringBuilder( 71 * 10 * 1024 + 21 );

    String query = "select number, voterid, data, sent, checkerid, othercheckers from loadVotes( ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, campaignid );
    st.setLong(2, numberfrom );

    ResultSet rs = st.executeQuery();

    long n = 0;

    while( rs.next() ) {

      n++;

      sb.append( rs.getLong(1) ).append("\n");
      sb.append( rs.getString(2) ).append("\n");
      sb.append( rs.getString(3) ).append("\n");
      sb.append( rs.getTimestamp(4).getTime() ).append("\n");
      sb.append( rs.getString(5) ).append("\n");
      sb.append( rs.getString(6) ).append("\n");
      sb.append("\n");
    }

    sb.insert(0, "n "+String.valueOf( n )+"\n\n");

    rs.close();
    st.close();

    return sb.toString();
  }


  public static boolean isVoteInInconsistencyReports( Connection dbConn, String voterid, String campaignid ) throws Exception {

    boolean isthere = false;

    String query = "select 1 from inconsistencyreports where voterid = ? and campaignid = ? limit 1";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, voterid );
    st.setString(2, campaignid );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      isthere = true;
    }

    rs.close();
    st.close();

    return isthere;
  }

  public static Vote getNextVoiceForCheckerCheck( Connection dbConn, String campaignid, String checkerid ) throws Exception {

    Vote vote = null;

    String query = "select * from getNextVoiceForCheckerCheck( ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, campaignid );
    st.setString(2, checkerid );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      if( rs.getString(1) != null ) {

        vote = new Vote();

        vote.voterid = rs.getString(1);
        vote.campaignid = campaignid;
        vote.fullname = rs.getString(2);
        vote.number = rs.getLong(3);
        vote.sdata = rs.getString(4);
        vote.sothercheckers = rs.getString(5);
        vote.locality = rs.getString(6);
        vote.district = rs.getString(7);
        vote.districtuncheckedleft = rs.getLong(8);
        vote.message = rs.getString(9);
        vote.helperid = rs.getString(10);
        vote.conflictid = rs.getString(11);

        if( vote.conflictid != null )
          vote.conflict = true;

        vote.parseData();
        vote.parseOtherCheckers();
      }
    }

    rs.close();
    st.close();

    return vote;
  }

  public static Vote getVoiceForHelperCheck( Connection dbConn, String campaignid, String helperid ) throws Exception {

    Vote vote = null;

    String query = "select * from getVoiceForHelperCheck( ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );
    st.setString(1, campaignid );
    st.setString(2, helperid );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      vote = new Vote();

      vote.voterid = rs.getString(1);
      vote.campaignid = campaignid;
      vote.fullname = rs.getString(2);
      vote.number = rs.getLong(3);
      vote.sdata = rs.getString(4);
      vote.state = rs.getString(5);
      vote.checkerid = rs.getString(6);
      vote.sothercheckers = rs.getString(7);
      vote.locality = rs.getString(8);
      vote.district = rs.getString(9);
      vote.districtuncheckedleft = rs.getLong(10);

      if( vote.voterid != null ) {

        vote.parseData();
        vote.parseOtherCheckers();
      }
      else {

        vote = null;
      }
    }

    rs.close();
    st.close();

    return vote;
  }

  public static void saveVoiceCheckChecker( Connection dbConn, Vote vote, String message ) throws Exception {

    String query = "select saveVoiceCheckChecker( ?, ?, ?, ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, vote.voterid );
    st.setString(2, vote.campaignid );
    st.setString(3, vote.checkerid );
    st.setString(4, vote.state );
    st.setString(5, message );

    st.execute();

    st.close();
  }

  public static void saveVoteConflictResolve( Connection dbConn, String conflictid, String voterid, String campaignid, String valid ) throws Exception {

    String query = "select saveVoteConflictResolve( ?, ?, ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, conflictid );
    st.setString(2, voterid );
    st.setString(3, campaignid );
    st.setString(4, valid );

    st.execute();

    st.close();
  }

  public static void saveCheckerConflictResolve( Connection dbConn, String conflictid, String checkerid, String valid ) throws Exception {

    String query = "select saveCheckerConflictResolve( ?, ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, conflictid );
    st.setString(2, checkerid );
    st.setString(3, valid );

    st.execute();

    st.close();
  }

  public static void saveVoiceCheckHelper( Connection dbConn, Vote vote, String message ) throws Exception {

    String query = "select saveVoiceCheckHelper( ?, ?, ?, ?, ? )";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, vote.voterid );
    st.setString(2, vote.campaignid );
    st.setString(3, vote.checkerid );
    st.setString(4, vote.state );
    st.setString(5, message );

    st.execute();

    st.close();
  }

  public static long loadStatisticsVotesTotal( Connection dbConn, String campaignid ) throws Exception {

    long votesTotal = 0;

    String query = "select count(*) from votes where campaignid = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1,campaignid );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      votesTotal = rs.getLong(1);
    }

    rs.close();
    st.close();

    return votesTotal;
  }

  public static long loadStatisticsVotesByLocality( Connection dbConn, String campaignid, String localityid ) throws Exception {

    long votesTotal = 0;

    String query = "select count(*) from votes as v inner join voters as vt on vt.id = v.voterid where v.campaignid = ? and vt.localityid = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, campaignid );
    st.setString(2, localityid );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      votesTotal = rs.getLong(1);
    }

    rs.close();
    st.close();

    return votesTotal;
  }

  public static long loadStatisticsVotesByDistrict( Connection dbConn, String campaignid, String localityid, String districtid ) throws Exception {

    long votesTotal = 0;

    String query = "select count(*) from votes as v inner join voters as vt on vt.id = v.voterid where v.campaignid = ? and vt.localityid = ? and vt.districtid = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, campaignid );
    st.setString(2, localityid );
    st.setString(3, districtid );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      votesTotal = rs.getLong(1);
    }

    rs.close();
    st.close();

    return votesTotal;
  }

  public static long loadStatisticsVotesByElementTotal( Connection dbConn, String campaignid, String code ) throws Exception {

    long votesTotal = 0;

    String query = "select count(*) from votes as v where v.campaignid = ? and v.data = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, campaignid );
    st.setString(2, code );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      votesTotal = rs.getLong(1);
    }

    rs.close();
    st.close();

    return votesTotal;
  }

  public static long loadStatisticsVotesByElementByLocality( Connection dbConn, String campaignid, String localityid, String code ) throws Exception {

    long votesTotal = 0;

    String query = "select count(*) from votes as v inner join voters as vt on vt.id = v.voterid where v.campaignid = ? and vt.localityid = ? and v.data = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, campaignid );
    st.setString(2, localityid );
    st.setString(3, code );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      votesTotal = rs.getLong(1);
    }

    rs.close();
    st.close();

    return votesTotal;
  }

  public static long loadStatisticsVotesByElementByDistrict( Connection dbConn, String campaignid, String localityid, String districtid, String code ) throws Exception {

    long votesTotal = 0;

    String query = "select count(*) from votes as v inner join voters as vt on vt.id = v.voterid where v.campaignid = ? and vt.localityid = ? and vt.districtid = ? and v.data = ?";

    PreparedStatement st = dbConn.prepareStatement( query );

    st.setString(1, campaignid );
    st.setString(2, localityid );
    st.setString(3, districtid );
    st.setString(4, code );

    ResultSet rs = st.executeQuery();

    if( rs.next() ) {

      votesTotal = rs.getLong(1);
    }

    rs.close();
    st.close();

    return votesTotal;
  }
}
