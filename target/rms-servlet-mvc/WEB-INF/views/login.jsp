<%@ page contentType="text/html;charset=UTF-8" %>
    <!doctype html>
    <html lang="vi">

    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Đăng nhập RMS</title>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/app.css?v=theme-all-ui-1">
    </head>

    <body class="login-page">
        <div class="login-card">
            <h1>Restaurant Management System</h1>
            <% if(request.getParameter("error")!=null){ %>
                <div class="alert alert-danger">Tên đăng nhập hoặc mật khẩu không đúng.</div>
                <% } %>
                    <% if(request.getParameter("logout")!=null){ %>
                        <div class="alert alert-success">Đã đăng xuất.</div>
                        <% } %>
                            <form method="post" action="${pageContext.request.contextPath}/login">
                                <div class="form-group"><label>Tên đăng nhập</label><input name="username" required
                                        autofocus></div>
                                <div class="form-group"><label>Mật khẩu</label><input type="password" name="password"
                                        required></div><button class="btn btn-primary" style="width:100%">Đăng
                                    nhập</button>
                            </form>
        </div>
    </body>

    </html>