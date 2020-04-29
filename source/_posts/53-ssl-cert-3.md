---
toc : true
title : "Java访问SSL地址，使用证书方式和免验证证书方式"
description : "Java访问SSL地址，使用证书方式和免验证证书方式"
tags : [
	"ssl",
	"openssl"
]
date : "2018-01-15 14:08:36"
categories : [
    "ssl"
]
menu : "main"
---

# 前文回顾

[《Openssl生成自签名证书，简单步骤》](https://ningyu1.github.io/site/post/51-ssl-cert/)中讲述了如何生成自签名证书。

[《使用自签名证书，简单步骤》](https://ningyu1.github.io/site/post/52-ssl-cert-2/)中讲述了如何使用自签名证书。

下面讲述在Java中如何访问SSL地址，使用证书访问和免验证证书访问。

# Java安装证书访问SSL地址

## 使用InstallCert安装证书

[《使用自签名证书，简单步骤》](https://ningyu1.github.io/site/post/52-ssl-cert-2/)这篇文章中介绍的InstallCert生成jssecacerts文件。
将ssecacerts文件放入%JAVA_HOME%\jre\lib\security 下即可。

## 使用keytool工具导入证书

```
keytool -import -alias xstore -keystore "cacerts_path" -file a.cer
```

* `cacerts_path`: 你的cacerts文件路径，一般在%JAVA_HOME%jre\lib\security\cacerts
* `a.cer`: 你需要导入的cer文件路径，可以是InstallCert生成的文件
* 密码使用jdk默认密码：`changeit`，或者在上面命令后增加`-storepass changeit`设置密码参数

通过上面两种方式可以将证书安装到jdk下，接下来就是java中如何访问ssl地址，不多说直接上代码。

## 自定义javax.net.ssl.X509TrustManager实现类

```
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import javax.net.ssl.X509TrustManager;

public class MyX509TrustManager implements X509TrustManager {

    @Override
    public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {

    }

    @Override
    public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {

    }

    @Override
    public X509Certificate[] getAcceptedIssuers() {
        return null;
    }

}
```

## 包装HttpsDemo类

`HttpsDemo`类中包装两个方法，`sendHttps`发起ssl地址请求，`sendHttp`发起普通地址请求

```
import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class HttpsDemo {

    private static final Logger logger = LoggerFactory.getLogger(HttpsDemo.class.getName());

    public static void sendHttps(String path, String outputStr) {
        InputStream inputStream = null;
        OutputStream outputStream = null;
        HttpsURLConnection httpUrlConn = null;
        BufferedReader bufferedReader = null;
        InputStreamReader inputStreamReader = null;
        StringBuffer buffer = new StringBuffer();
        try {
            // 创建SSLContext对象，并使用我们指定的信任管理器初始化
            TrustManager[] tm = { new MyX509TrustManager() };
            SSLContext sslContext = SSLContext.getInstance("SSL", "SunJSSE");
            sslContext.init(null, tm, new java.security.SecureRandom());
            // 从上述SSLContext对象中得到SSLSocketFactory对象
            SSLSocketFactory ssf = sslContext.getSocketFactory();

            URL url = new URL(path);
            httpUrlConn = (HttpsURLConnection) url.openConnection();
            httpUrlConn.setSSLSocketFactory(ssf);
            httpUrlConn.setDoOutput(true);
            httpUrlConn.setDoInput(true);
            httpUrlConn.setUseCaches(false);
            httpUrlConn.setRequestMethod("GET");
            httpUrlConn.connect();

            // 当有数据需要提交时
            if (null != outputStr) {
                outputStream = httpUrlConn.getOutputStream();
                // 注意编码格式，防止中文乱码
                outputStream.write(outputStr.getBytes("UTF-8"));
                outputStream.close();
            }

            // 将返回的输入流转换成字符串
            inputStream = httpUrlConn.getInputStream();
            inputStreamReader = new InputStreamReader(inputStream, "utf-8");
            bufferedReader = new BufferedReader(inputStreamReader);

            String str = null;
            while ((str = bufferedReader.readLine()) != null) {
                buffer.append(str);
            }
            logger.info("地址:{}, success, result:{}", path, buffer.toString());
        } catch (Exception e) {
            logger.error("地址:{}, error, exception:{}", path, e);
        } finally {
            if (bufferedReader != null) {
                IOUtils.closeQuietly(bufferedReader);
            }
            if (inputStreamReader != null) {
                IOUtils.closeQuietly(inputStreamReader);
            }
            if (inputStream != null) {
                IOUtils.closeQuietly(inputStream);
            }
            if (httpUrlConn != null) {
                httpUrlConn.disconnect();
            }
        }
    }

    public static void sendHttp(String path) {
        InputStream inputStream = null;
        ByteArrayOutputStream outputStream = null;
        HttpURLConnection urlConnection = null;
        try {
            URL url = new URL(path);
            urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.setRequestMethod("GET");
            urlConnection.setUseCaches(false);
            inputStream = urlConnection.getInputStream();
            outputStream = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int n = 0;
            while (-1 != (n = inputStream.read(buffer))) {
                outputStream.write(buffer, 0, n);
            }
            logger.info("地址:{}, success, result:{}", path, outputStream.toString());
        } catch (Exception e) {
            logger.error("地址:{}, error, exception:{}", path, e);
        } finally {
            if (outputStream != null) {
                IOUtils.closeQuietly(inputStream);
            }
            if (outputStream != null) {
                IOUtils.closeQuietly(outputStream);
            }
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
    }

	public static void main(String[] args) {
        sendHttps("https://xxx.com", null);
    }
}
```

上面访问ssl地址如果报错`java.security.cert.CertificateException: No name matching localhost found`那就是证书没有安装好，检查前面证书安装过程。

Java访问ssl其实是可以绕过证书验证的，可以不需要证书直接发起ssl地址请求，下面介绍一下。

# Java绕过证书验证访问SSL地址，达到免验证证书效果

这种方式是采用重写HostnameVerifier的verify方法配合X509TrustManager来处理授信所有host，下面直接上代码

```
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.cert.X509Certificate;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class HttpDemo {

    private static final Logger logger = LoggerFactory.getLogger(HttpDemo.class.getName());

    final static HostnameVerifier DO_NOT_VERIFY = new HostnameVerifier() {

        public boolean verify(String hostname, SSLSession session) {
            return true;
        }
    };

    public static void httpGet(String path) {
        StringBuffer tempStr = new StringBuffer();
        String responseContent = "";
        HttpURLConnection conn = null;
        try {
            // Create a trust manager that does not validate certificate chains
            trustAllHosts();
            URL url = new URL(path);
            HttpsURLConnection https = (HttpsURLConnection) url.openConnection();
            if (url.getProtocol().toLowerCase().equals("https")) {
                https.setHostnameVerifier(DO_NOT_VERIFY);
                conn = https;
            } else {
                conn = (HttpURLConnection) url.openConnection();
            }
            conn.connect();
            logger.info("地址:{}, success, result:{}", path, conn.getResponseCode() + " " + conn.getResponseMessage());
            // HttpURLConnection conn = (HttpURLConnection)
            // url.openConnection();

            // conn.setConnectTimeout(5000);
            // conn.setReadTimeout(5000);
            // conn.setDoOutput(true);
            //
            // InputStream in = conn.getInputStream();
            // conn.setReadTimeout(10*1000);
            // BufferedReader rd = new BufferedReader(new InputStreamReader(in,
            // "UTF-8"));
            // String tempLine;
            // while ((tempLine = rd.readLine()) != null) {
            // tempStr.append(tempLine);
            // }
            // responseContent = tempStr.toString();
            // System.out.println(responseContent);
            // rd.close();
            // in.close();
        } catch (Exception e) {
            logger.error("地址:{}, is error", e);
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
    }

    /**
     * Trust every server - dont check for any certificate
     */
    private static void trustAllHosts() {

        // Create a trust manager that does not validate certificate chains
        TrustManager[] trustAllCerts = new TrustManager[] { new X509TrustManager() {

            public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                return new java.security.cert.X509Certificate[] {};
            }

            public void checkClientTrusted(X509Certificate[] chain, String authType) {

            }

            public void checkServerTrusted(X509Certificate[] chain, String authType) {

            }
        } };

        // Install the all-trusting trust manager
        // 忽略HTTPS请求的SSL证书，必须在openConnection之前调用
        try {
            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, trustAllCerts, new java.security.SecureRandom());
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
        } catch (Exception e) {
            logger.error("trustAllHosts is error", e);
        }
    }

	public static void main(String[] args) {
        httpGet("https://xxx.com");
    }
}
```

以上代码需要注意一点：<span style="color:red">**忽略HTTPS请求的SSL证书，必须在openConnection之前调用。**</span>

# 常见错误

## 错误一

如果发生如下错误，请添加vm参数：`-Dhttps.protocols=TLSv1.1,TLSv1.2 -Djava.net.preferIPv4Stack=true`，一般是jdk1.7会发生这个错误，具体原因在[《使用自签名证书，简单步骤》](https://ningyu1.github.io/site/post/52-ssl-cert-2/)这篇文章中已经解释。

```
javax.net.ssl.SSLHandshakeException: Remote host closed connection during handshake
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:946) ~[na:1.7.0_45]
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1312) ~[na:1.7.0_45]
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1339) ~[na:1.7.0_45]
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1323) ~[na:1.7.0_45]
	at sun.net.www.protocol.https.HttpsClient.afterConnect(HttpsClient.java:563) ~[na:1.7.0_45]
	at sun.net.www.protocol.https.AbstractDelegateHttpsURLConnection.connect(AbstractDelegateHttpsURLConnection.java:185) ~[na:1.7.0_45]
	at sun.net.www.protocol.https.HttpsURLConnectionImpl.connect(HttpsURLConnectionImpl.java:153) ~[na:1.7.0_45]
	at HttpDemo.httpGet(HttpDemo.java:59) [classes/:na]
	at HttpDemo.main(HttpDemo.java:122) [classes/:na]
Caused by: java.io.EOFException: SSL peer shut down incorrectly
	at sun.security.ssl.InputRecord.read(InputRecord.java:482) ~[na:1.7.0_45]
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:927) ~[na:1.7.0_45]
	... 8 common frames omitted
```

## 错误二

如果发生如下错误，是因为没有找到匹配的证书。
如果使用证书的方式访问，请检查证书安装是否错误。
如果是免验证证书访问，请检查代码没有跳过证书验证。

```
javax.net.ssl.SSLHandshakeException: java.security.cert.CertificateException: No name matching xxxxxxx.com found
	at sun.security.ssl.Alerts.getSSLException(Alerts.java:192) ~[na:1.7.0_45]
	at sun.security.ssl.SSLSocketImpl.fatal(SSLSocketImpl.java:1884) ~[na:1.7.0_45]
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:276) ~[na:1.7.0_45]
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:270) ~[na:1.7.0_45]
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1341) ~[na:1.7.0_45]
	at sun.security.ssl.ClientHandshaker.processMessage(ClientHandshaker.java:153) ~[na:1.7.0_45]
	at sun.security.ssl.Handshaker.processLoop(Handshaker.java:868) ~[na:1.7.0_45]
	at sun.security.ssl.Handshaker.process_record(Handshaker.java:804) ~[na:1.7.0_45]
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:1016) ~[na:1.7.0_45]
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1312) ~[na:1.7.0_45]
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1339) ~[na:1.7.0_45]
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1323) ~[na:1.7.0_45]
	at sun.net.www.protocol.https.HttpsClient.afterConnect(HttpsClient.java:563) ~[na:1.7.0_45]
	at sun.net.www.protocol.https.AbstractDelegateHttpsURLConnection.connect(AbstractDelegateHttpsURLConnection.java:185) ~[na:1.7.0_45]
	at sun.net.www.protocol.https.HttpsURLConnectionImpl.connect(HttpsURLConnectionImpl.java:153) ~[na:1.7.0_45]
	at HttpsDemo.sendHttps(HttpsDemo.java:62) [classes/:na]
	at HttpsDemo.main(HttpsDemo.java:133) [classes/:na]
Caused by: java.security.cert.CertificateException: No name matching xxxxxxx.com found
	at sun.security.util.HostnameChecker.matchDNS(HostnameChecker.java:208) ~[na:1.7.0_45]
	at sun.security.util.HostnameChecker.match(HostnameChecker.java:93) ~[na:1.7.0_45]
	at sun.security.ssl.X509TrustManagerImpl.checkIdentity(X509TrustManagerImpl.java:347) ~[na:1.7.0_45]
	at sun.security.ssl.AbstractTrustManagerWrapper.checkAdditionalTrust(SSLContextImpl.java:847) ~[na:1.7.0_45]
	at sun.security.ssl.AbstractTrustManagerWrapper.checkServerTrusted(SSLContextImpl.java:814) ~[na:1.7.0_45]
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1323) ~[na:1.7.0_45]
	... 12 common frames omitted
```

