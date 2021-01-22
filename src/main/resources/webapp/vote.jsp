<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>
<%@ page import="org.vote.model.Vote" %>

<html>
<head>
  <title>Голосовать</title>
  <script type="text/javascript" src="/js/sha256.js"></script>
  <script type="text/javascript" src="/js/rotateimage.js"></script>
  <style>

.preview img {

  max-width: 600px;
  max-height: 600px;
}

#passportimage {

  max-width: 600px;
  max-height: 600px;
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
boolean voteDeclined = false;

String s = "";

try {
  dbConn = DbTools.connect();
  campaign = DbTools.getActiveCampaign( dbConn );

  if( request.getSession().getAttribute("voteconflictid") == null ) {

    isConflict = false;

    vote = DbTools.getVote( dbConn, request.getSession().getAttribute("voterid").toString(), campaign.id );
  }
  else { /* conflict */

    isConflict = true;

    conflictid = request.getSession().getAttribute("voteconflictid").toString();

    vote = DbTools.getVoteFromConflicts( dbConn, conflictid, request.getSession().getAttribute("voterid").toString(), campaign.id );
  }

  if( vote != null && vote.state.equals("-") )
    voteDeclined = true;
}
catch(Exception e) {

  e.printStackTrace();
}


%>

<%
  if( campaign == null ) {
%>
Сейчас не проводится голосование.
</body>
</html>
<%
  } else if( campaign != null ) {
%>
<%= campaign.name %><br>
<%= campaign.description %><br>
<br>

  <% if( vote == null || voteDeclined ) { %>

      <% if( voteDeclined ) { %>
Ваш голос был отклонён, вы можете внести изменения и отправить ещё раз<br>
<br>
      <% } %>

<%
    if( campaign.type.equals("select_one") ) {
%>

Выберите один из вариантов<br>
<br>

<form action="" id="vote_data">
<% for( int i=0; i<campaign.data.length; i++ ) {
     String display = campaign.data[i][0];
     String code = campaign.data[i][1];
%>
 <input type="radio" name="vote_radio" value="<%= code %>" id="<%= code %>"><label for="<%= code %>"><%= display %></label><br>
<% } %>
</form>
<br>

<%  } %>

Ваш паспорт<br>
<div>
<input type="hidden" id="id" value="<%= request.getSession().getAttribute("voterid") %>">

<% if( !isConflict ) { %>
<img id="passportimage" src="/files/id/<%= request.getSession().getAttribute("voterid") %>.jpg">
<% } else { %>
<img id="passportimage" src="/files/conflicts/voters/<%= conflictid %>/id/<%= request.getSession().getAttribute("voterid") %>.jpg">
<% } %>

</div>
<br>

<div>
  Ваше сегодняшнее фото <input id="photofile" type="file" style="display:none">
  <button onclick="document.querySelector('#photofile').click()">Обзор...</button>
  <!-- <button id="rotatephotoleft">Повернуть влево</button> -->
  <button id="rotatephotoright">Повернуть</button>
  <div class="preview">
  </div>
<div>
<br>


<div>
  Ваш выбор прописью с подписью от руки <input id="signaturefile" type="file" style="display:none">
  <button onclick="document.querySelector('#signaturefile').click()">Обзор...</button>
  <!-- <button id="rotatesignatureleft">Повернуть влево</button> -->
  <button id="rotatesignatureright">Повернуть</button>
  <div class="preview">
  </div>
<div>
<br>
<br>

<button id="sendbutton">Отправить голос</button>

<script>

      <% if( voteDeclined ) { %>
document.querySelector('#vote_data').value = vote.data;
      <% } %>

document.querySelector('#photofile').addEventListener('change', handleFileSelect, false);
document.querySelector('#signaturefile').addEventListener('change', handleFileSelect, false);

<!-- document.querySelector('#rotatephotoleft').addEventListener('click', rotateImage, false); -->
document.querySelector('#rotatephotoright').addEventListener('click', rotateImage, false);

<!-- document.querySelector('#rotatesignatureleft').addEventListener('click', rotateImage, false); -->
document.querySelector('#rotatesignatureright').addEventListener('click', rotateImage, false);

document.querySelector('#sendbutton').addEventListener('click', sendVote, false);

function handleFileSelect(evt) {
  var files = evt.target.files;
  var file = files[0];

  var id = evt.target.getAttribute('id');

  renderImage( file, id );
}

function sendVote() {

  var votedata = document.querySelector('#vote_data').vote_radio.value;
  var id = document.querySelector('#id').value;

  if( id.length == 0 ) {

    alert('Введите номер паспорта');
    document.querySelector('#id').focus();
    return;
  }

  if( votedata.length == 0 ) {

    alert('Неверный голос');
    return;
  }

  if( photoBlob == null ) {

    alert('Приложите ваше сегодняшнее фото');
    return;
  }

  if( signatureBlob == null ) {

    alert('Приложите фото вашей сегодняшней подпись от руки, желательно с отруки написанным выбором');
    return;
  }

  var formData = new FormData();
  formData.append('campaignid', '<%= campaign.id %>' );
  formData.append('votedata', votedata );
  formData.append('id', id );
  formData.append('photofile', photoBlob );
  formData.append('signaturefile', signatureBlob );

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          alert("Голос принят.");

          <% if( !isConflict ) { %>
            location.href = '/checkvoice';
          <% } else { %>
            location.href = '/checkvoice/conflict';
          <% } %>


        } else {

          alert("Голос не принят.");
        }
      }
  };

  // console.log( json );

  xmlhttp.open("POST", "/vote", true);
  xmlhttp.send( formData );

}

</script>

<% } else if( vote != null && vote.state.equals("+") ) { %>

Вы уже проголосовали<br>
<br>
<a href="/checkvoice">Проверить голос</a>

<% } %>



<%
  }
%>





</body>
</html>