import json

class User:
    def __init__(self, username, password):
        self.username = username
        self.password = password

class UserManager:
    def __init__(self, filename="config.json"):
        self.filename = filename
        self.users = self.load_users()

    def load_users(self):
        try:
            with open(self.filename, "r") as file:
                config_data = json.load(file)
                return {user["username"]: User(user["username"], user["password"]) for user in config_data.get("users", [])}
        except FileNotFoundError:
            return {}

    def save_users(self):
        with open(self.filename, "w") as file:
            users_data = [{"username": user.username, "password": user.password} for user in self.users.values()]
            json.dump({"users": users_data}, file)

    def register(self, username, password):
        if username in self.users:
            print("Username already exists. Please choose another one.")
            return False
        self.users[username] = User(username, password)
        self.save_users()
        print("Registration successful.")
        return True

    def login(self, username, password):
        if username in self.users and self.users[username].password == password:
            print("Login successful.")
            return True
        print("Invalid username or password.")
        return False

def display_login_interface(user_manager):
    print("Welcome to our e-commerce app!")

    while True:
        print("\n1. Login")
        print("2. Register")
        print("3. Exit")

        choice = input("Please choose an option: ")

        if choice == "1":
            username = input("Enter your username: ")
            password = input("Enter your password: ")
            if user_manager.login(username, password):
                break
        elif choice == "2":
            username = input("Enter a username: ")
            password = input("Enter a password: ")
            user_manager.register(username, password)
        elif choice == "3":
            print("Goodbye!")
            exit()
        else:
            print("Invalid choice. Please try again.")

if __name__ == "__main__":
    userManager = UserManager()
    display_login_interface(userManager)
