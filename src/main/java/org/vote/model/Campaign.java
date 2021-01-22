package org.vote.model;

import java.sql.Timestamp;

public class Campaign {

  public String id;
  public String name;
  public String description;
  public Timestamp created;
  public Timestamp todate;
  public String type;
  public String state;
  public String sdata;

  public String[][] data;

  public void parseData() {

    sdata = sdata.substring(2, sdata.length()-2);
    String[] arrays = sdata.split("\\},\\{");
    String[] onearray;

    data = new String[ arrays.length ][ 3 ];

    for( int i=0; i<arrays.length; i++ ) {

      onearray = arrays[i].split(",");

      data[i][0] = onearray[0];
      data[i][1] = onearray[1];
      data[i][2] = onearray[2];

      if( data[i][2] == "\"\"" ) data[i][2] = "";
    }
  }
}
