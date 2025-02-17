import { useState, useEffect } from "react";

const ModelSwitcher = () => {
    const [models, setModels] = useState([]);
    const [currentModel, setCurrentModel] = useState("");

    useEffect(() => {
        fetch("/config.json")
            .then(response => response.json())
            .then(data => {
                setModels(data.available_models);
                setCurrentModel(data.current_model);
            });
    }, []);

    const switchModel = (newModel) => {
        fetch(`/api/switch_model?model=${newModel}`, { method: "POST" })
            .then(() => setCurrentModel(newModel));
    };

    return (
        <div>
            <h3>Current Model: {currentModel}</h3>
            <select onChange={(e) => switchModel(e.target.value)} value={currentModel}>
                {models.map(model => (
                    <option key={model} value={model}>{model}</option>
                ))}
            </select>
        </div>
    );
};

export default ModelSwitcher;