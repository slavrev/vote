<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>
<%@ page import="org.vote.model.Vote" %>
<%@ page import="org.vote.model.Checker" %>
<%@ page import="java.text.SimpleDateFormat" %>

<html>
<head>
  <title>Проверка голосов</title>
  <style>

#passportimage, #passportimageupper, #passportimagelower {

  max-width: 600px;
  max-height: 600px;
}

#photoimage, #photoimageupper, #photoimagelower {

  max-width: 300px;
  max-height: 300px;
}

#signatureimage, #signatureimageupper, #signatureimagelower {

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

Checker checker = null;
Vote vote = null;
Vote vote0 = null;

String checkerid = "";

try {
  dbConn = DbTools.connect();
  campaign = DbTools.getActiveCampaign( dbConn );
  checker = DbTools.getChecker( dbConn, request.getSession().getAttribute("checkerid").toString() );

  vote = DbTools.getNextVoiceForCheckerCheck( dbConn, campaign.id, request.getSession().getAttribute("checkerid").toString() );

  if( vote != null && vote.conflict )
    vote0 = DbTools.getVote( dbConn, vote.voterid, campaign.id );

  dbConn.close();
}
catch(Exception e) {

  e.printStackTrace();
}

%>

<% if( checker.state.equals("n") ) { %>
Ваш аккаунт ещё не проверен. Дождитесь проверки администратором.
<% } else if( checker.state.equals("-") ) { %>
Ваши данные отклонены администратором.<br>
<br>
Причина: <%= checker.message %><br>
<br>
<a href="/registerchecker/fix">Загрузить заново</a>
<br>
</body>
</html>
<% return;
} %>

<% if( vote == null ) { %>
  Сейчас нет голосов на проверку.
<% } else { %>

<% if( !vote.conflict ) { %>

Локация: <%= vote.locality %><br>
Район: <%= vote.district %><br>
Осталось по району: <%= vote.districtuncheckedleft %><br>
<br>
<% if( campaign.type.equals("select_one") ) { %>

  <% for( int i=0; i<campaign.data.length; i++ ) {
      String display = campaign.data[i][0];
      String code = campaign.data[i][1];
      String value = campaign.data[i][2];
  %>

     <% if( code.equals( vote.data ) ) { %>
Голос: <%= display %><br>
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
ID: <input type="text" value="<%= vote.voterid %>" disabled><br>
<br>
ФИО: <input type="text" value="<%= vote.fullname %>" disabled><br>
<br>

<% if( vote.message != null ) { %>
Несоответствие: <%= vote.message %><br>
<br>
Проверил: <a href="/files/id/<%= vote.helperid %>.jpg"><%= vote.helperid %></a><br>
<% } %>
<br>

<% if( vote.othercheckers.length > 0 ) { %>
Также проверили:<br>
<% for( String otherchecker : vote.othercheckers ) { %>
<a href="/files/id/<%= otherchecker %>.jpg"><%= otherchecker %></a><br>
<% } %>
<br>
<% } %>

<button id="approve">Всё верно</button><button id="decline">Отклонить</button>
<br>
<br>

<script>

document.querySelector('#approve').addEventListener('click', approve, false);
document.querySelector('#decline').addEventListener('click', decline, false);

function approve() {

  var formData = new FormData();
  formData.append('voterid', '<%= vote.voterid %>' );
  formData.append('campaignid', '<%= vote.campaignid %>' );
  formData.append('who', 'checker' );
  formData.append('state', '+' );
  formData.append('checkerid', '<%= request.getSession().getAttribute("checkerid").toString() %>' );


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

function decline() {

  var message = prompt("В чём несоответствие, кратко:", "");
  if( message == null )
    return;

  var formData = new FormData();
  formData.append('voterid', '<%= vote.voterid %>' );
  formData.append('campaignid', '<%= vote.campaignid %>' );
  formData.append('who', 'checker' );
  formData.append('state', '-' );
  formData.append('message', message );
  formData.append('checkerid', '<%= request.getSession().getAttribute("checkerid").toString() %>' );

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          alert('Голос отклонён.');

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

<% } else { /* conflict */ %>

Локация: <%= vote.locality %><br>
Район: <%= vote.district %><br>
Осталось по району: <%= vote.districtuncheckedleft %><br>
<br>
Конфликт, необходимо выбрать верный паспорт и голос<br>
<br>

<%  String display0 = null;
    String display1 = null;  %>

<% if( campaign.type.equals("select_one") ) { %>

  <% for( int i=0; i<campaign.data.length; i++ ) {

     String display = campaign.data[i][0];
     String code = campaign.data[i][1];
     String value = campaign.data[i][2];

     if( code.equals( vote0.data ) )
       display0 = display;

     if( code.equals( vote.data ) )
      display1 = display;

  } %>

<% } %>
<br>

Вариант вверху:<br>
<br>
<%= display0 %><br>
<br>
<table>
  <tr>
    <td rowspan="2">
      <img id="passportimageupper" src="/files/id/<%= vote0.voterid %>.jpg">
    </td>
    <td>
      <img id="photoimageupper" src="/files/photo/<%= vote0.voterid %>.jpg">
    </td>
  </tr>
  <tr>
    <td>
      <img id="signatureimageupper" src="/files/sig/<%= campaign.id %>_<%= vote0.voterid %>.jpg">
    </td>
  </tr>
</table>
<br>
ID: <input type="text" value="<%= vote0.voterid %>" disabled><br>
<br>
ФИО: <input type="text" value="<%= vote0.fullname %>" disabled><br>
<br>
<br>
Вариант внизу:<br>
<br>
<%= display1 %><br>
<br>
<table>
  <tr>
    <td rowspan="2">
      <img id="passportimagelower" src="/files/conflicts/voters/<%= vote.conflictid %>/id/<%= vote.voterid %>.jpg">
    </td>
    <td>
      <img id="photoimagelower" src="/files/conflicts/voters/<%= vote.conflictid %>/photo/<%= vote.voterid %>.jpg">
    </td>
  </tr>
  <tr>
    <td>
      <img id="signatureimagelower" src="/files/conflicts/voters/<%= vote.conflictid %>/sig/<%= campaign.id %>_<%= vote.voterid %>.jpg">
    </td>
  </tr>
</table>
<br>
ID: <input type="text" value="<%= vote.voterid %>" disabled><br>
<br>
ФИО: <input type="text" value="<%= vote.fullname %>" disabled><br>
<br>
<br>
<button id="uppervalid">Вариант вверху</button><br>
<br>
<button id="lowervalid">Вариант внизу</button><br>
<br>
<button id="bothinvalid">Неверны оба</button><br>
<br>
<br>

<script>

document.querySelector('#uppervalid').addEventListener('click', upperValid, false);
document.querySelector('#lowervalid').addEventListener('click', lowerValid, false);
document.querySelector('#bothinvalid').addEventListener('click', bothInvalid, false);

function upperValid() {

  var formData = new FormData();
  formData.append('voterid', '<%= vote.voterid %>' );
  formData.append('campaignid', '<%= vote.campaignid %>' );
  formData.append('who', 'checker' );
  formData.append('state', '+' );
  formData.append('checkerid', '<%= request.getSession().getAttribute("checkerid").toString() %>' );

  formData.append('valid', 'registered');
  formData.append('conflictid', '<%= vote.conflictid %>');

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

  xmlhttp.open('POST', '/check/conflict', true);
  xmlhttp.send( formData );
}

function lowerValid() {

  var formData = new FormData();
  formData.append('voterid', '<%= vote.voterid %>' );
  formData.append('campaignid', '<%= vote.campaignid %>' );
  formData.append('who', 'checker' );
  formData.append('state', '+' );
  formData.append('checkerid', '<%= request.getSession().getAttribute("checkerid").toString() %>' );

  formData.append('valid', 'conflicted');
  formData.append('conflictid', '<%= vote.conflictid %>');

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

  xmlhttp.open('POST', '/check/conflict', true);
  xmlhttp.send( formData );
}

function bothInvalid() {

  var formData = new FormData();
  formData.append('voterid', '<%= vote.voterid %>' );
  formData.append('campaignid', '<%= vote.campaignid %>' );
  formData.append('who', 'checker' );
  formData.append('state', '+' );
  formData.append('checkerid', '<%= request.getSession().getAttribute("checkerid").toString() %>' );

  formData.append('valid', 'none');
  formData.append('conflictid', '<%= vote.conflictid %>');

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

  xmlhttp.open('POST', '/check/conflict', true);
  xmlhttp.send( formData );
}

</script>

<% } %>

<% } %>

</body>
</html>