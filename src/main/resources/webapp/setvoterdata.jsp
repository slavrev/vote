<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>
<%@ page import="org.vote.model.Locality" %>
<%@ page import="org.vote.model.District" %>
<%@ page import="java.util.List" %>

<html>
<head>
  <title>Голосовать</title>
  <script type="text/javascript" src="js/sha256.js"></script>
  <style>

.preview img {

  max-width: 400px;
  max-height: 400px;
};

  </style>
</head>
<body>

<%

String conflictid = null;
boolean isConflict = false;

if( request.getSession().getAttribute("voteconflictid") == null ) {

  isConflict = false;
}
else if( request.getSession().getAttribute("voteconflictid") != null ) {

  isConflict = true;

  conflictid = request.getSession().getAttribute("voteconflictid").toString();
}

Connection dbConn;
Campaign campaign = null;

String s = "";

List<Locality> localities = null;

try {
  dbConn = DbTools.connect();
  localities = DbTools.loadLocalities( dbConn );

  dbConn.close();
}
catch(Exception e) {

  e.printStackTrace();
}


%>

  Ваш паспорт: <%= request.getSession().getAttribute("voterid") %><br>
  <input type="hidden" id="id" value="<%= request.getSession().getAttribute("voterid") %>">
  <input type="hidden" id="passportimagehash" value="<%= request.getSession().getAttribute("passportimagehash") %>">
  <br>

  Ваше ФИО <br>
  <input type="text" id="fullname" value=""><br>
  <br>

  Ваш email <br>
  <input type="text" id="email" value=""><br>
  <br>

  Ваш населённый пункт:
  <select id="localityid">
  <% for( Locality locality : localities ) {
  %>
    <option value="<%= locality.id %>"><%= locality.name %></option>
  <% } %>
  </select><br>

  Ваш район:
  <select id="districtid">
    <option value="xxxx">Другое</option>
  </select><br>
  <br>

  <input type="checkbox" id="permission"><label for="permission">Я разрешаю использовать мои личные данные для голосования и подсчёта голосов</label><br>
  <input type="checkbox" id="sendemails" checked><label for="sendemails">Присылать мне уведомления на почту</label><br>
  <br>

  <button id="setvoterdatabutton">Отправить</button>

<script>

document.querySelector('#localityid').addEventListener('change', loadDistricts, false);

document.querySelector('#setvoterdatabutton').addEventListener('click', setVoterData, false);

document.querySelector('#localityid').value = 'xxxx';

function loadDistricts() {

  var localityid = document.querySelector('#localityid').value;

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {

      if (this.readyState == 4) {

        if( this.status == 200 ) {

          var json = JSON.parse( this.responseText );

          var districtElement = document.querySelector('#districtid');

          while( districtElement.firstChild )
            districtElement.removeChild( districtElement.lastChild );

          for( var i=0; i<json.length; i++ ) {

            var option = document.createElement('option');
            option.value = json[i].id;
            option.innerText = json[i].name;

            districtElement.appendChild( option );
          }

          districtElement.value = 'xxxx';

        } else {


        }
      }
  };

  xmlhttp.open("GET", "/getdistricts?localityid="+localityid, true);
  xmlhttp.send();
}

function setVoterData() {

  var id = document.querySelector('#id').value;
  var passportimagehash = document.querySelector('#passportimagehash').value;

  var fullname = document.querySelector('#fullname').value;
  var localityid = document.querySelector('#localityid').value;
  var districtid = document.querySelector('#districtid').value;

  if( id.length == 0 || passportimagehash.length == 0 ) {

    alert('Страница сфальсифицирована.');
    return;
  }

  if( fullname.length == 0 ) {

    alert('Введите ФИО');
    document.querySelector('#fullname').focus();
    return;
  }

  if( localityid.length == 0 ) {

    alert('Неверный код нас.пункта.');
    return;
  }

  if( districtid.length == 0 ) {

    alert('Неверный код района.');
    return;
  }

  if( !document.querySelector('#permission').checked ) {

    alert('Необходимо дать разрешения на использование личных данных, чтобы продолжить.');
    return;
  }

  var formData = new FormData();

  formData.append('id', id );
  formData.append('passportimagehash', passportimagehash );

  formData.append('fullname', fullname );
  formData.append('email', document.querySelector('#email').value );
  formData.append('localityid', localityid );
  formData.append('districtid', districtid );
  formData.append('sendemails', document.querySelector('#sendemails').checked );

  var path;

  <%if( !isConflict ) { %>

    path = '/setvoterdata';

  <% } else { %>

    path = '/setvoterdata/addvoteconflict';
  <% } %>

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          var targeturl = '<%= request.getParameter("targeturl") %>';

          if( path == '/setvoterdata/addvoteconflict' && targeturl == '/vote' )
            targeturl = '/vote/addvoteconflict';

          window.location.href = window.location.protocol+'//'+window.location.hostname+':'+window.location.port+targeturl;

        } else {

          alert('Не отправлено. Попробуйте ещё раз.');
        }
      }
  };

  xmlhttp.open("POST", path, true);
  xmlhttp.send( formData );
}

</script>

</body>
</html>