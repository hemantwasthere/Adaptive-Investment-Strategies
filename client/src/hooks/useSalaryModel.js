import * as tf from "@tensorflow/tfjs";
import { useEffect, useState } from "react";

export function useSalaryModel() {
  const [model, setModel] = useState(null);
  const loadModel = async () => {
    const model = await tf.loadLayersModel("/model.json");
    setModel(model);
  };

  const predict = async (experience) => {
    if (!model) return 0;
    const X_scales = [10.5, 1.1];
    const Y_scales = [122391.0, 37731.0];
    const exp_scaled = (experience - X_scales[1]) / (X_scales[0] - X_scales[1]);
    const exp_scaled_tensor = tf.tensor1d([exp_scaled]);
    const sal_scaled = await model.predict(exp_scaled_tensor).array();
    const salary = sal_scaled * (Y_scales[0] - Y_scales[1]) + Y_scales[1];
    return salary;
  };

  useEffect(() => {
    loadModel();
  }, []);

  return { model, predict };
}
