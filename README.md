# resrv
> it's time to resrv.

`resrv` is a cloud-based equipment reservation and usage tracking platform. It's designed for shared spaces like university labs, gyms, and clubs to introduce accountability, fairness, and data-driven insights into resource management.

## Team
* Alvis Ou
* Francis Deng
* Sky Sun
* Weijie Jiang

## Core Features
* **User Reservations:** Book equipment for defined time slots.
* **Real-time Availability:** A live dashboard shows what's available right now.
* **Accountability:** Automatic reminders before time is up and penalties for late returns or no-shows.
* **Conflict Resolution:** Handles recurring reservations and simultaneous requests.
* **Admin Analytics:** View usage heatmaps, underutilized equipment reports, and demand forecasting.

---

## Getting Started
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
    To run the test suite:
    ```bash
    bundle exec rails test
    ```