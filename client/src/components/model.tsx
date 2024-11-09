"use client";

import React from "react";

import { useSalaryModel } from "@/hooks/useSalaryModel";

const Model = () => {
  const { model, predict } = useSalaryModel();
  const [givenExp, setGivenExp] = React.useState(0);
  const [expectedSal, setExpectedSal] = React.useState(0);

  React.useEffect(() => {
    if (!model) return;
    predict(givenExp).then((res) => {
      setExpectedSal(res);
    });
  }, [model, predict, givenExp]);

  return (
    <div className="App">
      {!model && <>Loading the model...</>}
      {model && (
        <div>
          <div>
            <input
              type="number"
              value={givenExp}
              onChange={(e: any) => {
                setGivenExp(e.target.value);
              }}
            />
          </div>
          <div>{expectedSal}</div>
        </div>
      )}
    </div>
  );
};

export default Model;
