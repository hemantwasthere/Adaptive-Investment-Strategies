import React from "react";

import Holdings from "./holdings";

const Stats = () => {
  return (
    <div className="col-span-3 h-full bg-black/40 rounded-md py-4 px-5">
      <h4 className="text-white/90 text-3xl mb-2">How does it work?</h4>
      <p className="text-muted-foreground">
        Lorem ipsum dolor sit amet consectetur adipisicing elit. Inventore nam
        quia eius aliquam, itaque reprehenderit nihil sed ex laudantium eaque
        nulla officia incidunt rerum est? Quis, libero nesciunt unde fuga
        excepturi dignissimos provident autem quae hic. Iste veniam fugit
        quisquam consequatur? Consectetur libero debitis recusandae, dolores,
        eveniet vel iusto similique deleniti laudantium, error iure sint
        perferendis aliquid maxime. Enim, repellat.
      </p>

      <Holdings />
    </div>
  );
};

export default Stats;
