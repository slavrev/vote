<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>
<%@ page import="org.vote.model.Vote" %>
<%@ page import="java.text.SimpleDateFormat" %>

<html>
<head>
  <title>Помощь в проверке голосов</title>
  <style>

#passportimage {

  max-width: 600px;
  max-height: 600px;
}

#photoimage {

  max-width: 300px;
  max-height: 300px;
}

#signatureimage {

  max-width: 400px;
  max-height: 400px;
}

table {
  border: 0px solid #C4C1C1;
  border-collapse: collapse;
}

td, th {
  border: 0px solid #C4C1C1;
  text-align: left;
  vertical-align: bottom;
  padding-left: 0px;
  padding-right: 5px;
}

input:disabled {

  color: black;
}

  </style>
</head>
<body>
<%

Connection dbConn;
Campaign campaign = null;
Vote vote = null;

String s = "";

try {
  dbConn = DbTools.connect();
  campaign = DbTools.getActiveCampaign( dbConn );
  vote = DbTools.getVoiceForHelperCheck( dbConn, campaign.id, request.getSession().getAttribute("voterid").toString() );

  dbConn.close();
}
catch(Exception e) {

  e.printStackTrace();
}

%>

<% if( vote == null ) { %>
  Сейчас нет голосов на проверку.
<% } else { %>

Локация: <%= vote.locality %><br>
Район: <%= vote.district %><br>
Осталось по району: <%= vote.districtuncheckedleft %><br>

<br>
<% if( campaign.type.equals("select_one") ) { %>

  <% for( int i=0; i<campaign.data.length; i++ ) {
      String display = vote.data[i][0];
      String code = vote.data[i][1];
      String value = vote.data[i][2];
  %>

     <% if( code.equals( vote.data ) ) { %>
Голос: <%= display %>
     <% } %>

  <% } %>

<% } %>
<br>

<table>
  <tr>
    <td rowspan="2">
      <img id="passportimage" src="/files/id/<%= vote.voterid %>.jpg">
    </td>
    <td>
      <img id="photoimage" src="/files/photo/<%= vote.voterid %>.jpg">
    </td>
  </tr>
  <tr>
    <td>
      <img id="signatureimage" src="/files/sig/<%= campaign.id %>_<%= vote.voterid %>.jpg">
    </td>
  </tr>
</table>
<br>
ID: <input type="text" value="<%= vote.voterid %>" disabled ><br>
ФИО: <input type="text" value="<%= vote.fullname %>" disabled ><%= vote.fullname %><br>
<br>

<% if( vote.checkerid == null ) { %>
Ещё не проверен проверяющим
<% } else { %>
  <% if( vote.state.equals("+") ) { %>
    Проверен: <a href="/files/checkers/id/<%= vote.checkerid %>.jpg"><%= vote.checkerid %></>
  <% } %>
<% } %>
<br><br>

<% if( vote.othercheckers.length > 0 ) { %>
Также проверили:<br>
<% for( String otherchecker : vote.othercheckers ) { %>
<a href="/files/id/<%= otherchecker %>.jpg"><%= otherchecker %></a><br>
<% } %>
<% } %>
<br>

<button id="approve">Всё верно</button><button id="error">Есть несоответствие</button>

<script>

document.querySelector('#approve').addEventListener('click', approve, false);
document.querySelector('#error').addEventListener('click', error, false);

function approve() {

  var formData = new FormData();
  formData.append('voterid', '<%= vote.voterid %>' );
  formData.append('campaignid', '<%= vote.campaignid %>' );
  formData.append('who', 'helper' );
  formData.append('state', '+' );
  formData.append('checkerid', '<%= request.getSession().getAttribute("voterid").toString() %>' );


  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          alert('Сохранено.');

          location.reload();

        } else {

          alert('Не принято');

          location.reload();
        }
      }
  };

  xmlhttp.open('POST', '/check', true);
  xmlhttp.send( formData );
}

function error() {

  var message = prompt("В чём несоответствие, кратко:", "");
  if( message == null )
    return;

  var formData = new FormData();
  formData.append('voterid', '<%= vote.voterid %>' );
  formData.append('campaignid', '<%= vote.campaignid %>' );
  formData.append('who', 'helper' );
  formData.append('state', 'error' );
  formData.append('message', message );
  formData.append('checkerid', '<%= request.getSession().getAttribute("voterid").toString() %>' );

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          alert('Сохранено.');

          location.reload();

        } else {

          alert('Не принято');

          location.reload();
        }
      }
  };

  xmlhttp.open('POST', '/check', true);
  xmlhttp.send( formData );
}


</script>

<% } %>

</body>
</html>