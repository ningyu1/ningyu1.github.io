---
toc : true
title : "使用自签名证书，简单步骤"
description : "使用自签名证书，简单步骤"
tags : [
	"ssl",
	"InstallCert",
	"openssl"
]
date : "2018-01-12 19:13:36"
categories : [
    "ssl"
]
menu : "main"
---

在前文[《Openssl生成自签名证书，简单步骤》](https://ningyu1.github.io/site/post/51-ssl-cert/)中讲述了如何生成自签名证书，接下来整理证书使用遇到的问题。

证书使用的方式也有很多中，可以使用keytool生成或导入导出证书，这里对keytool不做过多描述，可以通过--help查看使用方法。

证书文件可以放到应用服务器、负载均衡、jvm中使用，如：IIS、tomcat、nginx或者loadbalance、jdk等等。

这里介绍一个简单的工具：`InstallCert`安装证书文件到jdk下，这个在本地调试连接ssl服务器代码的时候很有用。

如果我们的服务端使用的是jdk1.8（比如说：cas服务），访问的客户端（业务系统）也是jdk1.8，那么直接使用`InstallCert`安装即可.

如果我们的服务端使用的是jdk1.8，但是客户端使用jdk1.7会遇到什么问题？

我们都知道jdk1.7默认的TLS版本是1.0但是支持1.1和1.2，如何查看jdk支持的TLS版本呢？

可以使用jdk自带的`jcp（java control panel）`工具

`jcp（java control panel）`路径：`%JAVA_HOME%\jre\bin`

![](/img/ssl-cert/2.png)

点击高级，勾选TLS1.1 TSL1.2开启支持。

如果使用客户端程序（jdk1.7开发的）访问服务端程序（jdk1.8开发的），在使用`InstallCert`安装证书时会出现如下错误：

```
javax.net.ssl.SSLHandshakeException: Remote host closed connection during handshake
    at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:946) ~[na:1.7.0_45]
    at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1312) ~[na:1.7.0_45]
```

上面错误的意思就是服务器把你拒绝了！把你拒绝了！把你拒绝了！拒绝你的理由就是TLS版本不对。

下面我主要讲在客户端程序（jdk1.7开发的）访问服务端程序（jdk1.8开发的）的场景下安装证书如何解决上面的错误。

# 通过InstallCert源码安装证书

```
/*
 * Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 *   - Neither the name of Sun Microsystems nor the names of its
 *     contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import java.io.*;
import java.net.URL;

import java.security.*;
import java.security.cert.*;

import javax.net.ssl.*;

public class InstallCert {

    public static void main(String[] args) throws Exception {
    String host;
    int port;
    char[] passphrase;
    if ((args.length == 1) || (args.length == 2)) {
        String[] c = args[0].split(":");
        host = c[0];
        port = (c.length == 1) ? 443 : Integer.parseInt(c[1]);
        String p = (args.length == 1) ? "changeit" : args[1];
        passphrase = p.toCharArray();
    } else {
        System.out.println("Usage: java InstallCert <host>[:port] [passphrase]");
        return;
    }

    File file = new File("jssecacerts");
    if (file.isFile() == false) {
        char SEP = File.separatorChar;
        File dir = new File(System.getProperty("java.home") + SEP
            + "lib" + SEP + "security");
        file = new File(dir, "jssecacerts");
        if (file.isFile() == false) {
        file = new File(dir, "cacerts");
        }
    }
    System.out.println("Loading KeyStore " + file + "...");
    InputStream in = new FileInputStream(file);
    KeyStore ks = KeyStore.getInstance(KeyStore.getDefaultType());
    ks.load(in, passphrase);
    in.close();

    SSLContext context = SSLContext.getInstance("TLSv1.2");
    TrustManagerFactory tmf =
        TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
    tmf.init(ks);
    X509TrustManager defaultTrustManager = (X509TrustManager)tmf.getTrustManagers()[0];
    SavingTrustManager tm = new SavingTrustManager(defaultTrustManager);
    context.init(null, new TrustManager[] {tm}, null);
    SSLSocketFactory factory = context.getSocketFactory();

    System.out.println("Opening connection to " + host + ":" + port + "...");
    SSLSocket socket = (SSLSocket)factory.createSocket(host, port);
    socket.setSoTimeout(10000);
    try {
        System.out.println("Starting SSL handshake...");
        socket.startHandshake();
        socket.close();
        System.out.println();
        System.out.println("No errors, certificate is already trusted");
    } catch (SSLException e) {
        System.out.println();
        e.printStackTrace(System.out);
    }

    X509Certificate[] chain = tm.chain;
    if (chain == null) {
        System.out.println("Could not obtain server certificate chain");
        return;
    }

    BufferedReader reader =
        new BufferedReader(new InputStreamReader(System.in));

    System.out.println();
    System.out.println("Server sent " + chain.length + " certificate(s):");
    System.out.println();
    MessageDigest sha1 = MessageDigest.getInstance("SHA1");
    MessageDigest md5 = MessageDigest.getInstance("MD5");
    for (int i = 0; i < chain.length; i++) {
        X509Certificate cert = chain[i];
        System.out.println
            (" " + (i + 1) + " Subject " + cert.getSubjectDN());
        System.out.println("   Issuer  " + cert.getIssuerDN());
        sha1.update(cert.getEncoded());
        System.out.println("   sha1    " + toHexString(sha1.digest()));
        md5.update(cert.getEncoded());
        System.out.println("   md5     " + toHexString(md5.digest()));
        System.out.println();
    }

    System.out.println("Enter certificate to add to trusted keystore or 'q' to quit: [1]");
    String line = reader.readLine().trim();
    int k;
    try {
        k = (line.length() == 0) ? 0 : Integer.parseInt(line) - 1;
    } catch (NumberFormatException e) {
        System.out.println("KeyStore not changed");
        return;
    }

    X509Certificate cert = chain[k];
    String alias = host + "-" + (k + 1);
    ks.setCertificateEntry(alias, cert);

    OutputStream out = new FileOutputStream("jssecacerts");
    ks.store(out, passphrase);
    out.close();

    System.out.println();
    System.out.println(cert);
    System.out.println();
    System.out.println
        ("Added certificate to keystore 'jssecacerts' using alias '"
        + alias + "'");
    }

    private static final char[] HEXDIGITS = "0123456789abcdef".toCharArray();

    private static String toHexString(byte[] bytes) {
    StringBuilder sb = new StringBuilder(bytes.length * 3);
    for (int b : bytes) {
        b &= 0xff;
        sb.append(HEXDIGITS[b >> 4]);
        sb.append(HEXDIGITS[b & 15]);
        sb.append(' ');
    }
    return sb.toString();
    }

    private static class SavingTrustManager implements X509TrustManager {

    private final X509TrustManager tm;
    private X509Certificate[] chain;

    SavingTrustManager(X509TrustManager tm) {
        this.tm = tm;
    }

    public X509Certificate[] getAcceptedIssuers() {
//        throw new UnsupportedOperationException();
        return new X509Certificate[0];
    }

    public void checkClientTrusted(X509Certificate[] chain, String authType)
        throws CertificateException {
        throw new UnsupportedOperationException();
    }

    public void checkServerTrusted(X509Certificate[] chain, String authType)
        throws CertificateException {
        this.chain = chain;
        tm.checkServerTrusted(chain, authType);
    }
    }

}
```

上面源码我修改了`SSLContext context = SSLContext.getInstance("TLSv1.2");`，原本是TLS，这样在jdk1.7下会报错，尽管加了vm参数：`-Dhttps.protocols=TLSv1.1,TLSv1.2 -Djava.net.preferIPv4Stack=true`，依然会报错。

修改为TLSv1.2后，直接运行代码，参数为：你需要签名的域名

运行日志会出现如下错误（不用紧张，这个错误没有关系）：

```
Opening connection to login.xxxxx.com.cn:443...
Starting SSL handshake...

javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.ssl.Alerts.getSSLException(Alerts.java:192)
	at sun.security.ssl.SSLSocketImpl.fatal(SSLSocketImpl.java:1884)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:276)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:270)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1341)
	at sun.security.ssl.ClientHandshaker.processMessage(ClientHandshaker.java:153)
	at sun.security.ssl.Handshaker.processLoop(Handshaker.java:868)
	at sun.security.ssl.Handshaker.process_record(Handshaker.java:804)
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:1016)
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1312)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1339)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1323)
	at InstallCert.main(InstallCert.java:99)
Caused by: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:385)
	at sun.security.validator.PKIXValidator.engineValidate(PKIXValidator.java:292)
	at sun.security.validator.Validator.validate(Validator.java:260)
	at sun.security.ssl.X509TrustManagerImpl.validate(X509TrustManagerImpl.java:326)
	at sun.security.ssl.X509TrustManagerImpl.checkTrusted(X509TrustManagerImpl.java:231)
	at sun.security.ssl.X509TrustManagerImpl.checkServerTrusted(X509TrustManagerImpl.java:107)
	at InstallCert$SavingTrustManager.checkServerTrusted(InstallCert.java:195)
	at sun.security.ssl.AbstractTrustManagerWrapper.checkServerTrusted(SSLContextImpl.java:813)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1323)
	... 8 more
Caused by: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.provider.certpath.SunCertPathBuilder.engineBuild(SunCertPathBuilder.java:196)
	at java.security.cert.CertPathBuilder.build(CertPathBuilder.java:268)
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:380)
	... 16 more

Server sent 1 certificate(s):

 1 Subject EMAILADDRESS=ningyu@xxxxxx.com, CN=login.xxxxxxx.com, OU=JY, O=JY, L=Shanghai, ST=Shanghai, C=CN
   Issuer  EMAILADDRESS=ningyu@xxxxxx.com, CN=login.xxxxxxx.com, OU=JY, O=JY, L=Shanghai, ST=Shanghai, C=CN
   sha1    18 fe a4 26 de 9f ef 9f d0 12 f9 1b da e8 f4 6e 46 a3 ca e2 
   md5     53 02 53 bc 1f 5d e3 0f c2 ce a5 fa 43 7b 53 83 

Enter certificate to add to trusted keystore or 'q' to quit: [1]
```

出现上面错误没关系，在命令行输入：1，生成文件，会在执行目录下生成：jssecacerts，并且会输出下面的日志：

```
Enter certificate to add to trusted keystore or 'q' to quit: [1]
1

[
[
  Version: V1
  Subject: EMAILADDRESS=ningyu@xxxxx.com, CN=login.xxxxxxx.com, OU=JY, O=JY, L=Shanghai, ST=Shanghai, C=CN
  Signature Algorithm: SHA256withRSA, OID = 1.2.840.113549.1.1.11

  Key:  Sun RSA public key, 1024 bits
  modulus: 150111273197244637724411949927732292545940427223472330318676441758610292860528090849280500452765059055376192276098938042951946335160244351904122898746077164287399465663417510841977938344538423662939325238497292924898237072606839002269269847753256718676717424760603548961942760492908854629736493402902120207483
  public exponent: 65537
  Validity: [From: Fri Jan 12 15:15:03 CST 2018,
               To: Mon Jan 10 15:15:03 CST 2028]
  Issuer: EMAILADDRESS=ningyu@xxxxxx.com, CN=login.xxxxxx.com, OU=JY, O=JY, L=Shanghai, ST=Shanghai, C=CN
  SerialNumber: [    b9c6224c 0cf5ee1a]

]
  Algorithm: [SHA256withRSA]
  Signature:
0000: B7 F8 1B FB 3C 7E 46 31   9C 56 31 47 F5 79 2C AA  ....<.F1.V1G.y,.
0010: B0 E3 FB EA CF 6C 15 72   53 8B A9 36 1D 43 E0 AB  .....l.rS..6.C..
0020: 21 3C BD 65 51 11 B3 D6   5B 42 40 DB 07 9C 35 5C  !<.eQ...[B@...5\
0030: 84 9B B7 B8 02 5A E0 96   5D 5F 9E 5D B3 5F 85 A8  .....Z..]_.]._..
0040: 50 64 63 E7 12 B0 DF CA   48 DD 28 B7 B2 8D 42 33  Pdc.....H.(...B3
0050: A5 C1 E8 E1 41 08 F8 39   21 DD 6C BE 6E F1 CD EE  ....A..9!.l.n...
0060: F9 C0 DC 2F 1E 99 D2 DC   A3 2C C7 C2 64 ED 94 5E  .../.....,..d..^
0070: 32 6F CC B4 3D 93 B7 F8   09 8D F9 4E 39 CA 5E 53  2o..=......N9.^S

]

Added certificate to keystore 'jssecacerts' using alias 'login.xxxxxx.com-1'

```

这个时候再运行一遍`InstallCert`就不会报错，因为已经有jssecacerts文件，直接copy jssecacerts文件到%JAVA_HOME%\jre\lib\security下，就可以愉快的玩耍了。

这个在我们本地调试连接ssl服务器的代码时很有用，如果不把证书放入jdk下你会被无限的拒绝。