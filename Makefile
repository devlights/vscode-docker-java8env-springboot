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
