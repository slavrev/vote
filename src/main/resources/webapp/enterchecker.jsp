<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>

<html>
<head>
  <title>Голосовать</title>
  <script type="text/javascript" src="js/sha256.js"></script>
  <script type="text/javascript" src="js/rotateimage.js"></script>
  <style>

.preview img {

  max-width: 600px;
  max-height: 600px;
}

  a {
    font-family: sans-serif;
    text-decoration: none;
  }

  a:link {
    color: blue;
  }
  a:visited {
    color: blue;
  }
  a:hover {
    color: orange;
  }


  </style>
</head>
<body>


  Введите номер паспорта<br>
  <input type="text" id="id" name="id" value=""><br>
  <br>

  <div>
    Ваш паспорт <input id="passportfile" type="file" style="display:none">
    <button onclick="document.querySelector('#passportfile').click()">Обзор...</button>
    <!-- <button id="rotatepassportleft">Повернуть влево</button> -->
    <!-- <button id="rotatepassportright">Повернуть</button> -->
    <div class="preview">
    </div>
    <input type="hidden" id="passportimagehash" name="passportimagehash" value="">
  <div>

  <br>
  Не зарегистрированы? <a href="/registerchecker">Зарегистрироваться</a><br>
  <br>

  <button id="enterbutton">Войти</button>

<script>

document.querySelector('#passportfile').addEventListener('change', handleFileSelect, false);

<!-- document.querySelector('#rotatepassportleft').addEventListener('click', rotateImage, false); -->
<!-- document.querySelector('#rotatepassportright').addEventListener('click', rotateImage, false); -->

document.querySelector('#enterbutton').addEventListener('click', enter, false);

function handleFileSelect(evt) {
  var files = evt.target.files;
  var file = files[0];

  var id = evt.target.getAttribute('id');

  renderImage( file, id );
}

function enter() {

  var id = document.querySelector('#id').value;
  var passportimagehash = document.querySelector('#passportimagehash').value;

  if( id.length == 0 ) {

    alert('Введите номер паспорта');
    document.querySelector('#id').focus();
    return;
  }

  if( passportBlob == null ) {

    alert('Приложите фото вашего паспорта на развороте');
    return;
  }

  if( passportimagehash == null ) {

    alert('Что-то пошло не так. И хэш паспорта не посчитался. Обратитесь в администрацию системы.');
    return;
  }

  var formData = new FormData();
  formData.append('id', id );
  formData.append('passportimagehash', passportimagehash );


  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          window.location.href = window.location.protocol+'//'+window.location.hostname+':'+window.location.port+'<%= request.getParameter("targeturl") %>';

        } else if( this.status == 404 ) {

          alert("Такой проверяющий не зарегистрирован.");
        }
      }
  };

  xmlhttp.open("POST", "/enterchecker", true);
  xmlhttp.send( formData );
}

</script>

</body>
</html>