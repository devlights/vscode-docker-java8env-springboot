# はじめに

VSCode上で Remote Container を使い、SpringBootアプリを開発して

ステージ用の tomcat と springboot コンテナでも起動するように調整する。
（デバッグは、VSCodeでデバッグ起動して行う)

作業を行うエンジニアのローカルには java がインストールされている必要はない。

以下のものだけインストールされていれば良い。

- VSCode
- Docker

まず、以下の作業からスタート

- VSCodeで本ディレクトリを開く
- コマンドパレットで "reopen in container" を実行

# SpringBoot プロジェクト作成

```sh
$ spring init --dependencies=web demo
```

# resouces/application.properties を更新

```
server.servlet.context-path=/demo
```

# DemoApplication.java を更新

- War起動時に呼び出されるように SpringBootServletInitializer を継承

```java
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

@SpringBootApplication
public class DemoApplication extends SpringBootServletInitializer {

	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}

	@Override
	protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
		return builder.sources(DemoApplication.class);
	}
}
```

# HelloControllerを作成

```java
package com.example.demo;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @RequestMapping(path = "/hello")
    public String home() {
        return "helloworld";
    }
}
```

# VSCode 上で SpringBoot を起動してデバッグ

ここまでの調整で、VSCode 上で F5 または SPRING BOOT DASHBOARD よりデバッグ起動できるようになっている。

起動したら ```localhost:8080/demo/hello/``` で出力が表示されることを確認出来る。

# pom.xml を war 出力用に調整

- packaging を切替可能に
- spring-boot-starter-tomcat を dependency に追加
  - scope を切替可能に
- build を調整

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.5.6</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.example</groupId>
	<artifactId>demo</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>demo</name>
	<description>Demo project for Spring Boot</description>

	<!--
		プロファイルの指定で、jar と war を切り替える

		https://stackoverflow.com/questions/8247720/changing-packaging-based-on-active-profile-in-pom

		- [jar]
		  - $ mvn package [-Pdebug]
		- [war]
		  - $ mvn package -Prelease
	-->
	<packaging>${packaging.type}</packaging>
	<profiles>
        <profile>
            <id>debug</id>
            <activation>
                <activeByDefault>true</activeByDefault>
            </activation>
            <properties>
                <packaging.type>jar</packaging.type>
				<tomcat.provided></tomcat.provided>
            </properties>
		</profile>
        <profile>
            <id>release</id>
            <properties>
                <packaging.type>war</packaging.type>
				<tomcat.provided>provided</tomcat.provided>
            </properties>
        </profile>
	</profiles>

	<properties>
		<java.version>8</java.version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
            <scope>${tomcat.provided}</scope>
        </dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>

	<build>
		<finalName>${project.artifactId}</finalName>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-compiler-plugin</artifactId>
				<configuration>
				  <source>${java.version}</source>
				  <target>${java.version}</target>
				</configuration>
			  </plugin>	
		</plugins>
	</build>

</project>

```

# jar ファイル作成

```sh
$ (cd demo && mvn clean package -Pdebug)
```

以下で、SpringBootをtomcat内蔵版で起動

```sh
$ java -jar demo/target/demo.jar
```

# SpringBoot コンテナ用の Dockerfile 作成

```docker
FROM adoptopenjdk/openjdk8:alpine-slim

WORKDIR /app
COPY ./demo/target/demo.jar  /app

ENTRYPOINT [ "java", "-jar", "/app/demo.jar" ]
CMD [ "sleep", "infinity" ]
```

## Docker イメージビルド

```sh
$ docker image build -t stage-springboot -f Dockerfile.springboot ${PWD}
```

## Docker コンテナ起動

```sh
$ docker container run -dit -p 8082:8080 --rm --name stage-springboot-demo stage-springboot
```

## Docker コンテナ停止

```sh
$ docker container stop stage-springboot-demo
```

# war ファイル作成

```sh
$ (cd demo && mvn clean package -Prelease)
```

# Tomcat コンテナ用の Dockerfile 作成

```docker
# tomcat 8
#FROM tomcat:8-jdk8-temurin

# tomcat 9
FROM tomcat:9-jdk8-temurin

# tomcat 10
#   tomcat10 で SpringBoot は現状動かない
#     - https://github.com/spring-projects/spring-boot/issues/22414
#FROM tomcat:jdk8-temurin

WORKDIR /usr/local/tomcat/webapps/
COPY ./demo/target/demo.war  /usr/local/tomcat/webapps/
```

## Docker イメージビルド

```sh
$ docker image build -t stage-tomcat -f Dockerfile.tomcat ${PWD}
```

## Docker コンテナ起動

```sh
$ docker container run -dit -p 8081:8080 --rm --name stage-tomcat-demo stage-tomcat
```

## Docker コンテナ停止

```sh
$ docker container stop stage-tomcat-demo
```

# 作業しやすいように Makefile を用意

```makefile
build:
	(cd demo && mvn package -Pdebug -DskipTests=true && mvn package -Prelease -DskipTests=true)
	docker image build -t stage-tomcat -f Dockerfile.tomcat ${PWD}
	docker image build -t stage-springboot -f Dockerfile.springboot ${PWD}

clean:
	(cd demo && mvn clean)

start-tomcat:
	docker container run -dit -p 8081:8080 --rm --name stage-tomcat-demo stage-tomcat
	@echo "Launch webapp: http://localhost:8081/demo/hello/"

stop-tomcat:
	docker container stop stage-tomcat-demo

start-springboot:
	docker container run -dit -p 8082:8080 --rm --name stage-springboot-demo stage-springboot
	@echo "Launch webapp: http://localhost:8082/demo/hello/"

stop-springboot:
	docker container stop stage-springboot-demo
```

- clean ターゲット
  - ビルド生成物削除 (Jar and War)
- build ターゲット
  - jar作成
  - war作成
  - tomcat dockerイメージ作成
  - springboot dockerイメージ作成
- start-tomcat ターゲット
  - tomcat dockerイメージからコンテナ起動
  - 8081で起動
- stop-tomcat ターゲット
  - tomcat コンテナを停止 (同時にコンテナ削除)
- start-springboot ターゲット
  - springboot dockerイメージからコンテナ起動
  - 8082で起動
- stop-springboot ターゲット
  - springboot コンテナを停止（同時にコンテナ削除）

```sh
$ make clean
$ make build
$ make start-tomcat
$ make stop-tomcat
$ make start-springboot
$ make stop-tomcat
```

# 参考情報

- https://www.saka-en.com/java/spring-boot-war-tomcat/
- https://qiita.com/YumaInaura/items/1647e509f83462a37494
- https://qiita.com/rockbirds12/items/13aebcb33214c0bd4d4b
- https://stackoverflow.com/questions/52628246/spring-boot-web-app-not-running-on-tomcat-9
- https://qiita.com/bokuwakuma/items/04c0d82b6abfa334fce9
- https://docs.spring.io/spring-boot/docs/current/reference/html/application-properties.html
- https://github.com/spring-projects/spring-boot/issues/22414
