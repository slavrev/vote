<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>
<%@ page import="org.vote.model.Vote" %>
<%@ page import="java.text.SimpleDateFormat" %>

<html>
<head>
  <title>Ваш голос</title>
  <script type="text/javascript" src="/js/sha256.js"></script>
  <script type="text/javascript" src="/js/rotateimage.js"></script>
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
String conflictid = null;
boolean isConflict = false;
boolean isVoteInInconsistencyReports = false;

String voterid = request.getSession().getAttribute("voterid").toString();

String s = "";

try {
  dbConn = DbTools.connect();
  campaign = DbTools.getActiveCampaign( dbConn );

  if( request.getSession().getAttribute("voteconflictid") == null ) {

    isConflict = false;

    vote = DbTools.getVote( dbConn, voterid, campaign.id );
    isVoteInInconsistencyReports = DbTools.isVoteInInconsistencyReports( dbConn, voterid, campaign.id );
  }
  else { // conflict

    isConflict = true;

    conflictid = request.getSession().getAttribute("voteconflictid").toString();

    vote = DbTools.getVoteFromConflicts( dbConn, conflictid, voterid, campaign.id );
  }

  /*
  vote = DbTools.getVote( dbConn, voterid, campaign.id );
  isVoteInInconsistencyReports = DbTools.isVoteInInconsistencyReports( dbConn, voterid, campaign.id );
  */

  dbConn.close();
}
catch(Exception e) {

  e.printStackTrace();
}


%>

<%
  if( campaign == null ) {
%>
Сейчас не проводится голосование.
<%
  } else if( campaign != null ) {
%>
<%= campaign.name %><br>
<%= campaign.description %><br>
<%
  }
%>
<br>

<%
  if( vote == null ) {
%>

Вы ещё не голосовали<br>
<br>
<a href="/vote">Проголосовать</a>

<%
  } else if( vote != null ) {
%>

Ваш голос<br>
<br>
<% if( isConflict ) { %>
Ваш голос находится в конфликте, и пока не может быть посчитан, дождитесь, когда он будет проверен.<br>
<% } %>
<br>


<% for( int i=0; i<campaign.data.length; i++ ) {
     String display = campaign.data[i][0];
     String code = campaign.data[i][1];
     String value = campaign.data[i][2];

     if( code.equals( vote.data ) ) {
%>
<%= display %><br>
<% } %>
<% } %>

<br>

<% if( !isConflict )  { %>

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

<% } else { /* conflict */ %>

<table>
  <tr>
    <td rowspan="2">
      <img id="passportimage" src="/files/conflicts/voters/<%= conflictid %>/id/<%= vote.voterid %>.jpg">
    </td>
    <td>
      <img id="photoimage" src="/files/conflicts/voters/<%= conflictid %>/photo/<%= vote.voterid %>.jpg">
    </td>
  </tr>
  <tr>
    <td>
      <img id="signatureimage" src="/files/conflicts/voters/<%= conflictid %>/sig/<%= campaign.id %>_<%= vote.voterid %>.jpg">
    </td>
  </tr>
</table>

<% } %>

<br>

ID: <input type="text" value="<%= vote.voterid %>" disabled><br>
<br>
ФИО: <input type="text" id="fullname" value="<%= vote.fullname %>" disabled> <% if( vote.state.equals("-") ) { %><button id="changefullname" onclick="changeFullname()">Изменить</button><% } %><br>
<br>

Голос отправлен: <%= new SimpleDateFormat("dd.MM.yyyy HH:mm:ss").format( vote.sent ) %><br>
<br>

<% if( vote.state.equals("+") ) { %>
Голос принят<br>
<br>
Принял: <a href="/files/checkers/id/<%= vote.checkerid %>.jpg"><%= vote.checkerid %></a><br>
<% } else if( vote.state.equals("-") ) { %>
Голос отклонён<br>
Причина: <%= vote.message != null ? vote.message : "не указана" %><br>
<br>
Отклонил: <a href="/files/checkers/id/<%= vote.checkerid %>.jpg"><%= vote.checkerid %></a><br>
<br>
<a href="/vote">Отправить заново</a>
<% } else { %>
Не проверен<br>
<% } %>
<br>

<% if( vote.othercheckers.length > 0 ) { %>
Также проверили:<br>
<% for( String otherchecker : vote.othercheckers ) { %>
<a href="/files/id/<%= otherchecker %>.jpg"><%= otherchecker %></><br>
<% } %>
<br>
<% } %>
<br>

<script>

function changeFullname() {

  var fullname = prompt("Новое ФИО (как в паспорте):", "");
  if( fullname == null )
    return;

  var formData = new FormData();
  formData.append('fullname', fullname );

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          document.querySelector('#fullname').value = fullname;

          alert('Изменено.');

        } else {

          alert('Не отправлено');

        }
      }
  };

  xmlhttp.open('POST', '/setvoterdata/changefullname', true);
  xmlhttp.send( formData );
}

</script>


<% if( !isVoteInInconsistencyReports && vote.state.equals("+") ) { %>

<button id="error">Сообщить о фальсификации</button>

<script>

document.querySelector('#error').addEventListener('click', error, false);

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

          alert('Отправлено.');

          location.reload();

        } else {

          alert('Не отправлено');

          location.reload();
        }
      }
  };

  xmlhttp.open('POST', '/check', true);
  xmlhttp.send( formData );
}

</script>

<% } else if( isVoteInInconsistencyReports ) { %>
Вы сообщили о нарушении, голос ещё не проверен<br>
<br>
<% } %>

<%
  }
%>

<br>
<br>
<a href="/">На главную</a><br>
<br>
<br>

</body>
</html>