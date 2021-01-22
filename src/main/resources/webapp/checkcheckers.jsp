<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>
<%@ page import="org.vote.model.Vote" %>
<%@ page import="org.vote.model.Checker" %>
<%@ page import="java.text.SimpleDateFormat" %>

<html>
<head>
  <title>Проверка проверяющих</title>
  <style>

#passportimage, #passportimageupper, #passportimagelower {

  max-width: 600px;
  max-height: 600px;
}

#photoimage, #photoimageupper, #photoimagelower {

  max-width: 300px;
  max-height: 300px;
}

table {
  border: 0px solid #C4C1C1;
  border-collapse: collapse;
}

td, th {
  border: 0px solid #C4C1C1;
  text-align: left;
  vertical-align: top;
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
Checker checker0 = null;

long nchecked = 0;
long nnotchecked = 0;

String s = "";

try {
  dbConn = DbTools.connect();

  nchecked = DbTools.getCheckedCheckersCount( dbConn );
  nnotchecked = DbTools.getNotCheckedCheckersCount( dbConn );

  checker = DbTools.getNextCheckerCheck( dbConn );

  if( checker.conflict )
    checker0 = DbTools.getChecker( dbConn, checker.id );

  dbConn.close();
}
catch(Exception e) {

  e.printStackTrace();
}

%>

<% if( checker == null ) { %>
  Все проверяющие проверены.<br>
  <br>
  Всего проверяющих: <%= nchecked %><br>
<% } else { %>

  Проверенных: <%= nchecked %><br>
  Не проверенных: <%= nnotchecked %><br>
  <br>

<% if( !checker.conflict ) { %>

Локация: <%= checker.locality %><br>
Район: <%= checker.district %><br>
<br>

<table>
  <tr>
    <td rowspan="1">
      <img id="passportimage" src="/files/checkers/id/<%= checker.id %>.jpg">
    </td>
    <td>
      <img id="photoimage" src="/files/checkers/photo/<%= checker.id %>.jpg">
    </td>
  </tr>
</table>

<br>
ID: <input type="text" value="<%= checker.id %>" disabled ><br>
ФИО: <input type="text" value="<%= checker.fullname %>" disabled ><br>
E-mail: <input type="text" value="<%= checker.email %>" disabled ><br>
<br>

<button id="approve">Принять</button> <button id="decline">Отклонить</button>

<script>

document.querySelector('#approve').addEventListener('click', approve, false);
document.querySelector('#decline').addEventListener('click', decline, false);

function approve() {

  var formData = new FormData();
  formData.append('checkerid', '<%= checker.id %>' );
  formData.append('who', 'admin' );
  formData.append('state', '+' );

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

  xmlhttp.open('POST', '/admin/checkcheckers', true);
  xmlhttp.send( formData );
}

function decline() {

  var message = prompt("В чём несоответствие, кратко:", "");
  if( message == null )
    return;

  var formData = new FormData();
  formData.append('checkerid', '<%= checker.id %>' );
  formData.append('who', 'admin' );
  formData.append('state', '-' );
  formData.append('message', message );

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

  xmlhttp.open('POST', '/admin/checkcheckers', true);
  xmlhttp.send( formData );
}


</script>

<% } else { /* conflict */ %>

Конфликт паспортов, необходимо выбрать верный<br>
<br>
Вариант вверху:<br>
<br>
<table>
  <tr>
    <td rowspan="1">
      <img id="passportimageupper" src="/files/checkers/id/<%= checker0.id %>.jpg">
    </td>
    <td>
      <img id="photoimageupper" src="/files/checkers/photo/<%= checker0.id %>.jpg">
    </td>
  </tr>
</table>
<br>
ID: <input type="text" value="<%= checker0.id %>" disabled ><br>
ФИО: <input type="text" value="<%= checker0.fullname %>" disabled ><br>
E-mail: <input type="text" value="<%= checker0.email %>" disabled ><br>
Локация: <%= checker0.locality %><br>
Район: <%= checker0.district %><br>
<br>
<br>

Вариант внизу:<br>
<br>
<table>
  <tr>
    <td rowspan="1">
      <img id="passportimagelower" src="/files/conflicts/checkers/<%= checker.conflictid %>/id/<%= checker.id %>.jpg">
    </td>
    <td>
      <img id="photoimagelower" src="/files/conflicts/checkers/<%= checker.conflictid %>/photo/<%= checker.id %>.jpg">
    </td>
  </tr>
</table>
<br>
ID: <input type="text" value="<%= checker.id %>" disabled ><br>
ФИО: <input type="text" value="<%= checker.fullname %>" disabled ><br>
E-mail: <input type="text" value="<%= checker.email %>" disabled ><br>
Локация: <%= checker.locality %><br>
Район: <%= checker.district %><br>
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
  formData.append('checkerid', '<%= checker.id %>' );
  formData.append('who', 'admin' );
  formData.append('state', '-' );

  formData.append('valid', 'registered');
  formData.append('conflictid', '<%= checker.conflictid %>');

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

  xmlhttp.open('POST', '/admin/checkcheckers/conflict', true);
  xmlhttp.send( formData );
}

function lowerValid() {

  var formData = new FormData();
  formData.append('checkerid', '<%= checker.id %>' );
  formData.append('who', 'admin' );
  formData.append('state', '-' );

  formData.append('valid', 'conflicted');
  formData.append('conflictid', '<%= checker.conflictid %>');

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

  xmlhttp.open('POST', '/admin/checkcheckers/conflict', true);
  xmlhttp.send( formData );
}

function bothInvalid() {

  var formData = new FormData();
  formData.append('checkerid', '<%= checker.id %>' );
  formData.append('who', 'admin' );
  formData.append('state', '-' );

  formData.append('valid', 'none');
  formData.append('conflictid', '<%= checker.conflictid %>');

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

  xmlhttp.open('POST', '/admin/checkcheckers/conflict', true);
  xmlhttp.send( formData );
}

</script>

<% } %>

<% } %>

</body>
</html>