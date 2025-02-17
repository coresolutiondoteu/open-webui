Sure! Here’s a **polished step-by-step guide** based on everything we've discussed so far. This guide will walk you through the entire process of setting up a system to manage and run models with customizable parameters, allowing for history tracking, editing, and deleting old runs.

---

## **Step-by-Step Guide: Setting Up a Model Runner with History, Custom Parameters, and Model Management**

### **1. Overview**
We are building a system to run machine learning models (like Llama, Qwen, and others) with customizable start parameters. The system allows users to:
- **Run models** with custom parameters or from previous history.
- **Edit parameters** before running models again.
- **Delete old history entries** that are no longer needed.

This system will store model runs in a history file, track parameters, and provide a WebUI to interact with the models.

---

### **2. Prerequisites**
Before getting started, make sure you have the following installed:
- **Python 3.x**
- **Flask** for the web interface:
  ```bash
  pip install flask
  ```
- **Ollama** (or another model-running tool) for executing the models.

---

### **3. File Structure**
We’ll organize our files as follows:
```
/model_runner
    ├── run_model.py         # Python script to handle model execution and logging
    ├── run_history.json     # File to store the history of model runs
    ├── templates/
        ├── index.html       # Main page for running models and viewing history
        ├── history.html     # Page displaying the model run history
        └── edit_form.html   # Form to edit model parameters before running
    └── app.py               # Flask app to serve the WebUI and handle routes
```

---

### **4. Step-by-Step Setup**

#### **4.1. `run_model.py` - Model Execution & History Logging**

This file contains the functions for running the models, logging each run, and retrieving the history.

```python
import json
from datetime import datetime
import subprocess

RUN_HISTORY_FILE = 'run_history.json'

def log_run(model, parameters, output):
    """Log model run history"""
    try:
        with open(RUN_HISTORY_FILE, 'r') as f:
            run_history = json.load(f)
    except FileNotFoundError:
        run_history = []

    run_history.append({
        "model": model,
        "parameters": parameters,
        "timestamp": datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
        "output": output
    })

    with open(RUN_HISTORY_FILE, 'w') as f:
        json.dump(run_history, f, indent=4)

def run_model(model, parameters):
    """Run the model with parameters"""
    command = f"ollama run {model} {parameters}"
    try:
        output = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        log_run(model, parameters, output.stdout)
        return output.stdout
    except subprocess.CalledProcessError as e:
        log_run(model, parameters, e.stderr)
        return e.stderr

def display_run_history():
    """Display previous model runs"""
    try:
        with open(RUN_HISTORY_FILE, 'r') as f:
            run_history = json.load(f)
    except FileNotFoundError:
        run_history = []

    return run_history
```

---

#### **4.2. `app.py` - Flask Web Application**

This file contains the routes for handling the WebUI actions: running models, editing parameters, viewing history, and deleting entries.

```python
from flask import Flask, request, render_template
from run_model import run_model, display_run_history

app = Flask(__name__)

@app.route('/')
def home():
    """Home page with history and form to run models"""
    return render_template('index.html')

@app.route('/run_model', methods=['POST'])
def run_selected_model():
    """Run selected model with custom parameters"""
    model = request.form['model']
    parameters = request.form['parameters']
    
    output = run_model(model, parameters)
    return f"Model {model} run successfully with parameters {parameters}. Output: {output}"

@app.route('/run_with_history', methods=['POST'])
def run_with_history():
    """Run model with parameters selected from history"""
    model = request.form['model']
    parameters = request.form['parameters']
    
    output = run_model(model, parameters)
    return f"Model {model} run successfully with parameters {parameters}. Output: {output}"

@app.route('/edit_history', methods=['GET'])
def edit_history():
    """Allow editing parameters before running the model"""
    model = request.args['model']
    parameters = request.args['parameters']
    
    return render_template('edit_form.html', model=model, parameters=parameters)

@app.route('/delete_history', methods=['POST'])
def delete_history():
    """Delete a specific history entry"""
    model = request.form['model']
    parameters = request.form['parameters']
    
    # Load existing history
    try:
        with open('run_history.json', 'r') as f:
            run_history = json.load(f)
    except FileNotFoundError:
        run_history = []

    # Remove the entry that matches the model and parameters
    run_history = [entry for entry in run_history if not (entry['model'] == model and entry['parameters'] == parameters)]
    
    # Save the updated history back
    with open('run_history.json', 'w') as f:
        json.dump(run_history, f, indent=4)

    return "History entry deleted successfully. <a href='/history'>Go back to history</a>"

@app.route('/history')
def history():
    """Display the history of model runs"""
    run_history = display_run_history()
    return render_template('history.html', history=run_history)

if __name__ == '__main__':
    app.run(debug=True)
```

---

#### **4.3. HTML Templates**

- **`index.html`** - Main page for running models and viewing history.

```html
<form action="/run_model" method="POST">
    <label for="model">Select Model:</label>
    <select name="model" id="model">
        <option value="Llama-3.1-8B">Llama 3.1 8B</option>
        <option value="Qwen-2.5-7B">Qwen 2.5 7B</option>
        <!-- Add other models here -->
    </select><br><br>

    <label for="parameters">Enter Parameters:</label><br>
    <textarea name="parameters" id="parameters" rows="4" cols="50"></textarea><br><br>

    <input type="submit" value="Run Model">
</form>

<h3>Model Run History:</h3>
<a href="/history">View History</a>
```

- **`history.html`** - Page displaying the model run history with options to re-run, edit, or delete entries.

```html
<h2>Model Run History</h2>
<ul>
    {% for entry in history %}
    <li>
        <strong>{{ entry['model'] }}</strong><br>
        Parameters: <pre>{{ entry['parameters'] }}</pre><br>
        Timestamp: {{ entry['timestamp'] }}<br>
        Output: {{ entry['output'] }}<br><br>

        <form action="/run_with_history" method="POST" style="display:inline;">
            <input type="hidden" name="model" value="{{ entry['model'] }}">
            <input type="hidden" name="parameters" value="{{ entry['parameters'] }}">
            <button type="submit">Run with these parameters</button>
        </form>

        <form action="/edit_history" method="GET" style="display:inline;">
            <input type="hidden" name="model" value="{{ entry['model'] }}">
            <input type="hidden" name="parameters" value="{{ entry['parameters'] }}">
            <button type="submit">Edit</button>
        </form>

        <form action="/delete_history" method="POST" style="display:inline;">
            <input type="hidden" name="model" value="{{ entry['model'] }}">
            <input type="hidden" name="parameters" value="{{ entry['parameters'] }}">
            <button type="submit" onclick="return confirm('Are you sure you want to delete this entry?')">Delete</button>
        </form>
        
        <hr>
    </li>
    {% endfor %}
</ul>
```

- **`edit_form.html`** - Form for editing parameters before rerunning the model.

```html
<h2>Edit Parameters for {{ model }}</h2>
<form action="/run_model" method="POST">
    <label for="model">Select Model:</label>
    <input type="text" name="model" id="model" value="{{ model }}" readonly><br><br>

    <label for="parameters">Edit Parameters:</label><br>
    <textarea name="parameters" id="parameters" rows="4" cols="50">{{ parameters }}</textarea><br><br>

    <input type="submit" value="Run Model with Edited Parameters">
</form>
```

---

### **5. Running the Application**
To run the application:
1. Save all the files as described.
2. In the terminal, navigate to the project directory and run the Flask app:

```bash
python app.py
```

3. Visit **`http://127.0.0.1:5000/`** in your browser to access the app.

---

### **6. Additional Improvements**

- **Security**: Add user authentication and input validation to prevent unauthorized users from running models or deleting history.
- **UI Improvements**: Use CSS frameworks like **Bootstrap** to improve the look and feel of the WebUI.
- **Model Options**: Add more options for each model, such as **presets** for specific tasks (e.g., fine-tuning parameters for certain scenarios).

---

This concludes the setup guide! Let me know if you need help implementing additional features or have any other questions.


You're absolutely right! I forgot to incorporate the **Docker setup**, **Docker Compose**, and the **initial script** for managing models and running them within containers. I will integrate those details into the final step-by-step guide. Here’s the complete, **polished version** of the guide, which includes all aspects: Docker setup, running models, history management, and more.

---

# **Complete Step-by-Step Guide: Running Models in Docker with Flask Web Interface**

### **1. Overview**
This guide walks you through setting up a system that runs machine learning models (such as Llama, Qwen, etc.) within Docker containers. The system tracks each model's parameters and run history, allowing you to:
- **Run models with custom parameters**.
- **Edit parameters** before rerunning models.
- **Delete old run history**.
- **Switch between models** with the option to stop and unload the current model.

The system includes:
1. **Docker** for running models in containers.
2. **Flask Web Interface** for interacting with the models and viewing/editing history.
3. **Model History Management** with options to select, edit, and delete past runs.

---

### **2. Prerequisites**
Ensure you have the following tools installed:
- **Docker**: To containerize and run models.
- **Docker Compose**: To manage multi-container applications.
- **Python 3.x**: For the Flask web app.
- **Flask**: For the web interface.
  ```bash
  pip install flask
  ```

Also, ensure **Docker** and **Docker Compose** are set up and running on your system.

---

### **3. Docker Setup**

#### **3.1. Dockerfile for Model Container**

This `Dockerfile` is used to create a Docker image for running machine learning models. It includes the necessary dependencies and scripts to run models like Llama, Qwen, etc.

```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install required Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the current directory contents into the container
COPY . .

# Expose the port for the web interface
EXPOSE 5000

# Command to run the app
CMD ["python", "app.py"]
```

This file:
- Starts from a **Python slim image**.
- Installs required system dependencies and Python packages.
- Copies your project files into the container.
- Exposes **port 5000** for the Flask web interface.

#### **3.2. `docker-compose.yml` - Docker Compose for Model Running**

Create a `docker-compose.yml` file to define and run multiple services (containers), including the model runner and Flask web interface.

```yaml
version: '3.8'
services:
  model_runner:
    build: .
    container_name: model_runner
    environment:
      - MODEL_TYPE=Llama-3.1-8B
      - RUN_PARAMETERS=
    volumes:
      - ./model_runner:/app
    ports:
      - "5000:5000"
    restart: always
```

This file:
- **Builds** the Docker container from the `Dockerfile`.
- Defines a **volume** to mount the project folder into the container.
- Maps **port 5000** for accessing the Flask web interface.

---

### **4. Flask Web Application Setup**

#### **4.1. `run_model.py` - Model Execution and History Logging**

This Python script will handle the execution of models, logging each run to a JSON history file.

```python
import json
from datetime import datetime
import subprocess

RUN_HISTORY_FILE = 'run_history.json'

def log_run(model, parameters, output):
    """Log model run history"""
    try:
        with open(RUN_HISTORY_FILE, 'r') as f:
            run_history = json.load(f)
    except FileNotFoundError:
        run_history = []

    run_history.append({
        "model": model,
        "parameters": parameters,
        "timestamp": datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
        "output": output
    })

    with open(RUN_HISTORY_FILE, 'w') as f:
        json.dump(run_history, f, indent=4)

def run_model(model, parameters):
    """Run the model with parameters"""
    command = f"ollama run {model} {parameters}"
    try:
        output = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        log_run(model, parameters, output.stdout)
        return output.stdout
    except subprocess.CalledProcessError as e:
        log_run(model, parameters, e.stderr)
        return e.stderr

def display_run_history():
    """Display previous model runs"""
    try:
        with open(RUN_HISTORY_FILE, 'r') as f:
            run_history = json.load(f)
    except FileNotFoundError:
        run_history = []

    return run_history
```

#### **4.2. `app.py` - Flask Web Interface**

This is the main Flask application that handles routes for the web interface to view history, run models, and edit/delete entries.

```python
from flask import Flask, request, render_template
from run_model import run_model, display_run_history
import json

app = Flask(__name__)

@app.route('/')
def home():
    """Home page with history and form to run models"""
    return render_template('index.html')

@app.route('/run_model', methods=['POST'])
def run_selected_model():
    """Run selected model with custom parameters"""
    model = request.form['model']
    parameters = request.form['parameters']
    
    output = run_model(model, parameters)
    return f"Model {model} run successfully with parameters {parameters}. Output: {output}"

@app.route('/run_with_history', methods=['POST'])
def run_with_history():
    """Run model with parameters selected from history"""
    model = request.form['model']
    parameters = request.form['parameters']
    
    output = run_model(model, parameters)
    return f"Model {model} run successfully with parameters {parameters}. Output: {output}"

@app.route('/edit_history', methods=['GET'])
def edit_history():
    """Allow editing parameters before running the model"""
    model = request.args['model']
    parameters = request.args['parameters']
    
    return render_template('edit_form.html', model=model, parameters=parameters)

@app.route('/delete_history', methods=['POST'])
def delete_history():
    """Delete a specific history entry"""
    model = request.form['model']
    parameters = request.form['parameters']
    
    # Load existing history
    try:
        with open('run_history.json', 'r') as f:
            run_history = json.load(f)
    except FileNotFoundError:
        run_history = []

    # Remove the entry that matches the model and parameters
    run_history = [entry for entry in run_history if not (entry['model'] == model and entry['parameters'] == parameters)]
    
    # Save the updated history back
    with open('run_history.json', 'w') as f:
        json.dump(run_history, f, indent=4)

    return "History entry deleted successfully. <a href='/history'>Go back to history</a>"

@app.route('/history')
def history():
    """Display the history of model runs"""
    run_history = display_run_history()
    return render_template('history.html', history=run_history)

if __name__ == '__main__':
    app.run(debug=True)
```

---

#### **4.3. HTML Templates**

- **`index.html`**: Main page for running models and viewing history.

```html
<form action="/run_model" method="POST">
    <label for="model">Select Model:</label>
    <select name="model" id="model">
        <option value="Llama-3.1-8B">Llama 3.1 8B</option>
        <option value="Qwen-2.5-7B">Qwen 2.5 7B</option>
        <!-- Add other models here -->
    </select><br><br>

    <label for="parameters">Enter Parameters:</label><br>
    <textarea name="parameters" id="parameters" rows="4" cols="50"></textarea><br><br>

    <input type="submit" value="Run Model">
</form>

<h3>Model Run History:</h3>
<a href="/history">View History</a>
```

- **`history.html`**: Display model run history with options to edit, delete, or rerun with selected parameters.

```html
<h2>Model Run History</h2>
<ul>
    {% for entry in history %}
    <li>
        <strong>{{ entry['model'] }}</strong><br>
        Parameters: <pre>{{ entry['parameters'] }}</pre><br>
        Timestamp: {{ entry['timestamp'] }}<br>
        Output: {{ entry['output'] }}<br><br>

        <form action="/run_with_history" method="POST" style="display:inline;">
            <input type="hidden" name="model" value="{{ entry['model'] }}">
            <input type="hidden" name="parameters" value="{{ entry['parameters'] }}">
            <button type="submit">Run with these parameters</button>
        </form>

        <form action="/edit_history" method="GET" style="display:inline;">
            <input type="hidden" name="model" value="{{ entry['model'] }}">
            <input type="hidden" name="parameters" value="{{ entry['parameters'] }}">
            <button type="submit">Edit</button>
        </form>

        <form action="/delete_history" method="POST" style="display:inline;">
            <input type="hidden" name="model" value="{{ entry['model'] }}">
            <input type="hidden" name="parameters" value="{{ entry['parameters'] }}">
            <button type="submit" onclick="return confirm('Are you sure you want to delete this entry?')">Delete</button>
        </form>
        
        <hr>
    </li>
    {% endfor %}
</ul>
```

- **`edit_form.html`**: Form to edit model parameters before running.

```html
<h2>Edit Parameters for {{ model }}</h2>
<form action="/run_model" method="POST">
    <label for="model">Select Model:</label>
    <input type="text" name="model" id="model" value="{{ model }}" readonly><br><br>

    <label for="parameters">Edit Parameters:</label><br>
    <textarea name="parameters" id="parameters" rows="4" cols="50">{{ parameters }}</textarea><br><br>

    <input type="submit" value="Run Model with Edited Parameters">
</form>
```

---

### **5. Running the Application**

1. **Build and Start the Docker Containers**:

```bash
docker-compose up --build
```

2. The application will be available at **`http://127.0.0.1:5000/`**. You can now run models, view history, edit parameters, and delete old entries.

---

### **6. Additional Improvements**

- **Security**: Add user authentication (Flask-Login) to secure model management.
- **Input Validation**: Ensure parameters are validated before running.
- **Model Presets**: Implement predefined configurations for each model (e.g., specific parameters for fine-tuning).

---

This concludes the **complete guide**! Let me know if you need further assistance or have any questions about implementation.