# [resrv](https://resrv-fc94874a0a23.herokuapp.com/)
> it's time to resrv.

`resrv` is a cloud-based equipment reservation and usage tracking platform. It's designed for shared spaces like university labs, gyms, and clubs to introduce accountability, fairness, and data-driven insights into resource management.

## 🌟 Core Features
* **User Reservations:** Book equipment for defined time slots.
* **Real-time Availability:** A live dashboard shows what's available right now.
* **Accountability:** Automatic reminders before time is up and penalties for late returns or no-shows.
* **Conflict Resolution:** Handles recurring reservations and simultaneous requests.
* **Admin Analytics:** View usage heatmaps, underutilized equipment reports, and demand forecasting.

## 💻 Tech Stack
<p align="left">
  <img src="https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white" alt="Ruby">
  <img src="https://img.shields.io/badge/Ruby_on_Rails-CC0000?style=for-the-badge&logo=ruby-on-rails&logoColor=white" alt="Ruby on Rails">
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Heroku-430098?style=for-the-badge&logo=heroku&logoColor=white" alt="Heroku">
  <br>
  <img src="https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white" alt="HTML5">
  <img src="https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white" alt="CSS3">
  <img src="https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black" alt="JavaScript">
  <img src="https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white" alt="jQuery">
</p>

## 👥 Team
* Alvis Ou
* Francis Deng
* Sky Sun
* Weijie Jiang

---

## 🛠 Getting Started
This guide will get you a copy of the project up and running on your local machine for development and testing.

### Prerequisites
You will need the following tools installed on your system:
* **Ruby:** We recommend using `rbenv` to manage Ruby versions.
* **Bundler:** The Ruby dependency manager.
* **PostgreSQL:** A database for the application (or as specified in `Gemfile`).

### Setup and Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/AlvisOu/resrv.git
    cd resrv
    ```

2.  **Set the Ruby Version:**
    Our project uses Ruby 3.3.8. `rbenv` will handle this automatically.
    ```bash
    rbenv install
    ```

3.  **Install Bundler:**
    (If you haven't already installed it for this Ruby version)
    ```bash
    gem install bundler
    ```

4.  **Install Dependencies:**
    This command reads the `Gemfile` and installs all the required gems (libraries) for the project.
    ```bash
    bundle install
    ```

5.  **Create and Set Up the Database:**
    
    ```bash
    # Creates the database (development and test)
    bundle exec rails db:create
    
    # Runs the database migrations to create tables
    bundle exec rails db:migrate
    ```

6.  **(Optional) Seed the Database:**
    ```bash
    bundle exec rails db:seed
    ```

### How to Run
1.  **Start the Web Server:**
    This will run the application using the `puma` web server (default for Rails).
    ```bash
    bundle exec rails server
    ```
    You can now visit the app in your browser at `http://localhost:3000`.

2.  **Run Tests:**
    This project uses multiple test suites. You can run them using the following commands:
    * RSpec (Unit & Integration Tests):
    ```bash
    # Run all RSpec tests
    bundle exec rspec

    # Run a specific spec file
    bundle exec rspec spec/models/user_spec.rb
    ```
    * Cucumber (Acceptance & Feature Tests):
    ```bash
    # Run all Cucumber features
    bundle exec cucumber

    # ex. Run a specific feature file
    bundle exec cucumber features/user_flow.feature
    ```