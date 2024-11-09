import nbformat
from nbconvert import ExecutePreprocessor

def run_notebook(notebook_path, timeout=600):
    # Load the notebook
    with open(notebook_path, 'r', encoding='utf-8') as f:
        nb = nbformat.read(f, as_version=4)
    
    # Create a notebook executor
    ep = ExecutePreprocessor(timeout=timeout, kernel_name='python3')
    
    # Execute the notebook
    ep.preprocess(nb, {'metadata': {'path': './'}})
    
    # Collect outputs
    outputs = []
    for cell in nb.cells:
        if 'outputs' in cell:
            for output in cell['outputs']:
                if output.output_type == 'stream':
                    outputs.append(output['text'])
                elif output.output_type == 'execute_result':
                    outputs.append(output['data']['text/plain'])
    
    return outputs

# Run the notebook and get the output
notebook_outputs = run_notebook('path/to/your_notebook.ipynb')
print(notebook_outputs)