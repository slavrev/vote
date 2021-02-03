<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>
<%@ page import="org.vote.model.Locality" %>
<%@ page import="org.vote.model.District" %>
<%@ page import="java.util.List" %>

<html>
<head>
  <title>Регистрация проверяющего</title>
  <script type="text/javascript" src="js/sha256.js"></script>
  <script type="text/javascript" src="js/rotateimage.js"></script>
  <style>

.preview img {

  max-width: 600px;
  max-height: 600px;
}

  </style>
</head>
<body>

<%

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

  Введите номер паспорта<br>
  <input type="text" id="id" name="id" value=""><br>
  <br>

  <div>
    Ваш паспорт <input id="passportfile" type="file" style="display:none">
    <button onclick="document.querySelector('#passportfile').click()">Обзор...</button>
    <!-- <button id="rotatepassportleft">Повернуть влево</button> -->
    <button id="rotatepassportright">Повернуть</button>
    <button id="savepassportfile" style="display:none">Сохранить</button>
    <div class="preview">
    </div>
    <input type="hidden" id="passportimagehash" name="passportimagehash" value="">
  <div>
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

  <button id="registerbutton">Зарегистрироваться</button>

<script>

document.querySelector('#passportfile').addEventListener('change', handleFileSelect, false);
document.querySelector('#photofile').addEventListener('change', handleFileSelect, false);

<!-- document.querySelector('#rotatepassportleft').addEventListener('click', rotateImage, false); -->
document.querySelector('#rotatepassportright').addEventListener('click', rotateImage, false);
document.querySelector('#savepassportfile').addEventListener('click', savePassportFile, false);

<!-- document.querySelector('#rotatephotoleft').addEventListener('click', rotateImage, false); -->
document.querySelector('#rotatephotoright').addEventListener('click', rotateImage, false);

document.querySelector('#localityid').addEventListener('change', loadDistricts, false);

document.querySelector('#registerbutton').addEventListener('click', registerChecker, false);

document.querySelector('#localityid').value = 'xxxx';

function handleFileSelect(evt) {
  var files = evt.target.files;
  var file = files[0];

  var id = evt.target.getAttribute('id');

  renderImage( file, id );
}

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


function registerChecker() {

  var id = document.querySelector('#id').value;
  var passportimagehash = document.querySelector('#passportimagehash').value;

  var fullname = document.querySelector('#fullname').value;
  var email = document.querySelector('#email').value;
  var localityid = document.querySelector('#localityid').value;
  var districtid = document.querySelector('#districtid').value;

  if( id.length == 0 ) {

    alert('Введите номер паспорта');
    document.querySelector('#id').focus();
    return;
  }

  if( passportBlob == null ) {

    alert('Приложите фото вашего паспорта на развороте');
    return;
  }

  if( photoBlob == null ) {

    alert('Приложите ваше сегодняшнее фото');
    return;
  }

  if( !passportImageSaved ) {

    alert('Сохраните изменённое фото паспорта. Иначе вы не сможете войти далее.');
    return;
  }

  if( passportimagehash == null ) {

    alert('Что-то пошло не так. И хэш паспорта не посчитался. Обратитесь в администрацию системы.');
    return;
  }

  if( fullname.length == 0 ) {

    alert('Введите ФИО');
    document.querySelector('#fullname').focus();
    return;
  }

  if( email.length == 0 ) {

    alert('Введите email');
    document.querySelector('#email').focus();
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
  formData.append('passportfile', passportBlob );
  formData.append('photofile', photoBlob );
  formData.append('passportimagehash', passportimagehash );
  formData.append('registeredsecs', passportImageModifiedSecs );

  formData.append('fullname', fullname );
  formData.append('email', email );
  formData.append('localityid', localityid );
  formData.append('districtid', districtid );
  formData.append('sendemails', document.querySelector('#sendemails').checked );

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          alert('Проверяющий зарегистрирован. Дождитесь подтверждения. Оно придёт к вам на почту.');

          window.location.href = window.location.protocol+'//'+window.location.hostname+':'+window.location.port;

        } else {

          alert('Не зарегистрирован.');
        }
      }
  };

  xmlhttp.open("POST", "/registerchecker", true);
  xmlhttp.send( formData );
}

</script>

</body>
</html>