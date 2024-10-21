# locust load testing, using locustfile.py
from locust import HttpUser, task, between,constant

class MyUser(HttpUser):
    wait_time = constant(0)

    # def on_start(self):
    #     self.login()
    # @task
    # def login(self):
    #     response = self.client.post("/login", json={"email": "mohamedbalkhi169@gmail.com", "password": "11223344123aS@"})
    #     self.token = response.cookies['refreshToken']

    # @task
    # def refresh(self):
    #     self.client.post("/refresh", cookies={"refreshToken": self.token})

    @task
    def test(self):
        self.client.get("/test")



if __name__ == "__main__":
    import os
    os.system("locust -f locustfile.py --host=http://127.0.0.1:8080/api/auth")