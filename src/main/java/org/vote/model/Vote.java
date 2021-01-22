package org.vote.model;

import java.sql.Timestamp;

public class Vote {
  public String voterid;
  public String campaignid;
  public Long number;
  public Timestamp sent;
  public String state;
  // public boolean checked;
  public String checkerid;

  public String sdata;
  public String sothercheckers;

  public String data;
  public String[] othercheckers;

  public String locality; // для отображения
  public String district; // для отображения
  public long districtuncheckedleft;

  public String message;
  public String helperid;

  public String conflictid;
  public boolean conflict;

  public String fullname;


  public void parseData() {

    /*
    sdata = sdata.substring(1, sdata.length()-1);

    if( sdata.length() == 0 )
      data = new String[0];
    else
      data = sdata.split(",");

     */
    data = sdata;
  }

  public void parseOtherCheckers() {

    if( sothercheckers != null ) {

      sothercheckers = sothercheckers.substring(1, sothercheckers.length()-1);

      if( sothercheckers.length() == 0 )
        othercheckers = new String[0];
      else
        othercheckers = sothercheckers.split(",");
    }
    else
      othercheckers = new String[0];
  }
}
