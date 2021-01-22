<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <!--    <script type="text/javascript" src="js/sha256.js"></script>-->
  <title>Vote</title>
  <style>

  html, body {
    height: 100%;
    margin: 0;
  }

  .full-height {
    height: 100%;
    background: yellow;
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

<div style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center;">
  <div style="display: flex; flex-direction: column; justify-content: center; flex-wrap: wrap;">
    <a href="/vote">Буду голосовать</a><br>
    <div style="height: 10px;"></div>
    <a href="/checkvoice">Проверить свой голос</a><br>
    <div style="height: 20px;"></div>
    <a href="/check">Буду проверять</a><br>
    <div style="height: 10px;"></div>
    <a href="/check/help">Буду помогать проверять голоса</a><br>
    <div style="height: 20px;"></div>
    <a href="/statistics">Статистика голосования</a><br>
    <div style="height: 10px;"></div>
    <a href="/count">Подсчёт голосов</a><br>
    <div style="height: 20px;"></div>

    <% if( request.getSession().getAttribute("voterid") != null || request.getSession().getAttribute("checkerid") != null ) { %>
    <a href="/exit">Выйти</a><br>
    <% } else { %>
      <!-- voterid is null -->
    <% } %>


    <!--    <div style="height: 20px;"></div>-->
    <!--    <a href="/enter/admin">Азъ есмь админъ</a><br>-->
  </div>
</div>

</body>
</html>
