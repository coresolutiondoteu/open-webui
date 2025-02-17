I get your idea — you want to have a way to configure the **start parameters** for each model before it runs, while also displaying a **history** of previous runs, along with the ability to **define** the parameters for the model each time you start it.

This concept can be applied in the following way:

- **Model History:** Display a log of previous model runs with their **parameters** and any **output**.
- **Custom Parameters:** Before starting a model, the user can set **custom parameters** (like specific configurations for the model run).

This will require:
1. **Tracking model run history.**
2. **Allowing the user to define run parameters** before starting a model.
3. **Integrating a UI** where these parameters can be customized before each model run.

Let's break this down into the necessary steps:

---

## **1. Track Run History**

First, you need to create a way to **log each model run** and store the **start parameters** used for each run. This can be done by saving each run's **parameters** in a log file (e.g., `run_history.json`).

### **Step 1.1: Modify the Model Run Script for Logging**

Create a `run_history.json` file to store the history:

```json
[
    {
        "model": "Llama-3.1-8B",
        "parameters": "--num-gpu-layers=10 --batch-size=4",
        "timestamp": "2025-02-17T15:30:00",
        "output": "Model started successfully"
    },
    {
        "model": "Qwen-2.5-7B",
        "parameters": "--cpu-offload",
        "timestamp": "2025-02-16T12:00:00",
        "output": "Model started successfully"
    }
]
```

Modify the **model run script** (`run_model.py`) to log each run’s parameters and output:

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
```

### **Step 1.2: Create History Display Function**

To display the history, create a function to read from `run_history.json`:

```python
def display_run_history():
    """Display previous model runs"""
    try:
        with open(RUN_HISTORY_FILE, 'r') as f:
            run_history = json.load(f)
    except FileNotFoundError:
        run_history = []

    for entry in run_history:
        print(f"Model: {entry['model']}")
        print(f"Parameters: {entry['parameters']}")
        print(f"Timestamp: {entry['timestamp']}")
        print(f"Output: {entry['output']}")
        print("-" * 40)
```

---

## **2. Add User Input for Custom Parameters**

Before each model run, you want the user to be able to define custom start parameters. You can add a UI field where the user can input or modify these parameters.

If you're using a **web interface**, you can create a simple form where the user selects the model and inputs custom parameters.

### **Step 2.1: Create WebUI for Selecting Model and Defining Parameters**

If you're building a **simple Flask app**, the HTML form could look like this:

#### HTML Form Example (for WebUI):
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
```

#### Flask Backend Example:

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

@app.route('/history')
def history():
    """Display the history of model runs"""
    run_history = display_run_history()
    return render_template('history.html', history=run_history)

if __name__ == '__main__':
    app.run(debug=True)
```

This will allow the user to:
- **Select a model.**
- **Define custom parameters**.
- **Run the model** with the specified parameters and log the run.

---

## **3. Display Model History and Parameters**

In the WebUI, you’ll want to display the history of model runs. You can show the parameters used in each run and the output.

### **Step 3.1: Display Run History (in WebUI)**

#### History HTML Template (`history.html`):
```html
<h2>Model Run History</h2>
<ul>
    {% for entry in history %}
    <li>
        <strong>{{ entry['model'] }}</strong><br>
        Parameters: {{ entry['parameters'] }}<br>
        Timestamp: {{ entry['timestamp'] }}<br>
        Output: {{ entry['output'] }}<br><br>
    </li>
    {% endfor %}
</ul>
```

This will render a list of the previous model runs, showing the parameters used and their output.

---

## **4. Putting It All Together**

### **In summary:**

1. **Model History:** Every time a model is run, the parameters and output are logged in `run_history.json`.
2. **User Input:** Before running a model, the user can define custom parameters via a form in the **WebUI**.
3. **Model Execution:** When the model is executed, the parameters are used to run it, and the history is updated.
4. **History Display:** The user can view the history of model runs with detailed parameters and output.

---

## **Next Steps:**

- **Security:** Make sure that user inputs are sanitized properly, especially if you're running this in a production environment. You can implement **authentication** to limit who can run the models.
- **Additional Features:** You could add options for **parameter presets** for different use cases, or the ability to **save** frequently used configurations.

---

Would you like help setting up any particular part of this, or additional customization for the parameters and model execution process?


Great! You want to enhance the functionality so users can **select and run** a model from the **history**, **edit the parameters**, and also **delete old entries** that are no longer needed. Here's how we can extend the **WebUI** and backend to add this functionality.

### Key Features to Implement:
1. **Select from history**: The user can select a past model run from the history and rerun it with the same parameters.
2. **Edit parameters**: The user can edit the selected parameters before rerunning the model.
3. **Delete old entries**: The user can delete specific runs from the history.

---

### **1. Extend the History View (Web Interface)**

#### **Step 1.1: Display History with Select, Edit, and Delete Options**

You can modify the **history view** to show each model's parameters along with **Edit** and **Delete** buttons.

#### **Updated History HTML Template** (`history.html`):

```html
<h2>Model Run History</h2>
<ul>
    {% for entry in history %}
    <li>
        <strong>{{ entry['model'] }}</strong><br>
        Parameters: <pre>{{ entry['parameters'] }}</pre><br>
        Timestamp: {{ entry['timestamp'] }}<br>
        Output: {{ entry['output'] }}<br><br>

        <!-- Button to re-run with the same parameters -->
        <form action="/run_with_history" method="POST" style="display:inline;">
            <input type="hidden" name="model" value="{{ entry['model'] }}">
            <input type="hidden" name="parameters" value="{{ entry['parameters'] }}">
            <button type="submit">Run with these parameters</button>
        </form>

        <!-- Button to edit the parameters -->
        <form action="/edit_history" method="GET" style="display:inline;">
            <input type="hidden" name="model" value="{{ entry['model'] }}">
            <input type="hidden" name="parameters" value="{{ entry['parameters'] }}">
            <button type="submit">Edit</button>
        </form>

        <!-- Button to delete the history entry -->
        <form action="/delete_history" method="POST" style="display:inline;">
            <input type="hidden" name="model" value="{{ entry['model'] }}">
            <input type="hidden" name="parameters" value="{{ entry['parameters'] }}">
            <button type="submit" onclick="return confirm('Are you sure you want to delete this entry?')">Delete</button>
        </form>
        
        <hr>
    </li>
    {% endfor %}
</ul>

<h3>Create a New Run:</h3>
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
```

- **Run with these parameters**: The user can **re-run** a selected history entry using the exact same parameters.
- **Edit**: The user can **edit** the parameters and rerun the model with the updated parameters.
- **Delete**: The user can **delete** the history entry if it’s no longer needed.

---

### **2. Backend Logic for Handling History Actions**

#### **Step 2.1: Run with History Parameters**

This route will allow users to **rerun** a model with the selected parameters from the history:

```python
@app.route('/run_with_history', methods=['POST'])
def run_with_history():
    """Run model with parameters selected from history"""
    model = request.form['model']
    parameters = request.form['parameters']
    
    output = run_model(model, parameters)
    return f"Model {model} run successfully with parameters {parameters}. Output: {output}"
```

This simply reruns the model using the **same parameters** stored in the history.

---

#### **Step 2.2: Edit History Parameters**

This route will allow the user to **edit** the parameters of a specific model run before executing it again.

```python
@app.route('/edit_history', methods=['GET'])
def edit_history():
    """Allow editing parameters before running the model"""
    model = request.args['model']
    parameters = request.args['parameters']
    
    return render_template('edit_form.html', model=model, parameters=parameters)
```

#### **Create an Edit Form (HTML)** (`edit_form.html`):

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

This allows the user to modify the parameters and **run the model with the new settings**.

---

#### **Step 2.3: Delete History Entry**

This route will allow the user to **delete** an entry from the model run history.

```python
@app.route('/delete_history', methods=['POST'])
def delete_history():
    """Delete a specific history entry"""
    model = request.form['model']
    parameters = request.form['parameters']
    
    # Load existing history
    try:
        with open(RUN_HISTORY_FILE, 'r') as f:
            run_history = json.load(f)
    except FileNotFoundError:
        run_history = []

    # Remove the entry that matches the model and parameters
    run_history = [entry for entry in run_history if not (entry['model'] == model and entry['parameters'] == parameters)]
    
    # Save the updated history back
    with open(RUN_HISTORY_FILE, 'w') as f:
        json.dump(run_history, f, indent=4)

    return "History entry deleted successfully. <a href='/history'>Go back to history</a>"
```

This route will remove the selected history entry from the JSON file.

---

### **3. Display Updated History after Deleting or Editing**

After a deletion or edit, you can display the updated **history** view by redirecting the user to the history page:

```python
@app.route('/history')
def history():
    """Display the history of model runs"""
    try:
        with open(RUN_HISTORY_FILE, 'r') as f:
            run_history = json.load(f)
    except FileNotFoundError:
        run_history = []

    return render_template('history.html', history=run_history)
```

This will ensure that the user sees the **latest history** after making edits or deletions.

---

### **4. Putting It All Together**

Now, you have a full-fledged system where users can:

- **Run models with parameters from history**.
- **Edit parameters** before running again.
- **Delete old history entries** that are no longer needed.

---

### **5. Additional Features (Optional)**

- **Confirmation pop-ups**: You can add a confirmation dialog when deleting to avoid accidental deletions (we’ve added a basic one in the HTML).
- **User Authentication**: For better security, you could add user authentication to prevent unauthorized users from modifying the history.
- **Better UI**: You can use JavaScript libraries or CSS frameworks like **Bootstrap** for a more polished UI.

---

## **Would you like to implement any additional features**, such as security for the app or advanced validation for the user input? Or do you need help with anything else in the process?