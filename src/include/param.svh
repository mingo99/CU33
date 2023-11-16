`define PEA33_ROW 3
`define PEA33_COL 8
`define PEA33_WGT_WIDTH 8*`PEA33_ROW
`define PEA33_IFM_WIDTH 8*(`PEA33_ROW+`PEA33_COL-1)

`define TILE_RUN `PEA33_COL
`define TILE_LEN 16
`define RF_AWIDTH $clog2(`TILE_LEN)

`define CHN_64 1
`define CHN_128 2
`define CHN_256 4
`define CHN_512 8
`define CHN_1024 16
`define CHN_2048 32
`define CHN_WIDTH 6
// `define CHN_OFT_WIDTH 6
`define CHN_OFT_WIDTH 3

`define FMS_WIDTH 8
`define OFM_WIDTH 32

// For simulation
`define CHI (`CHN_64<<`CHN_OFT_WIDTH)
`define CHO (`CHN_64<<`CHN_OFT_WIDTH)
`define IFM_SIZE 8'd200
`define OFM_SIZE (`IFM_SIZE-2)
`define TILE_ROW (`OFM_SIZE/`TILE_RUN+1)
`define TILE_COL (`OFM_SIZE/`TILE_LEN+1)
`define IFM_LEN `TILE_ROW*`TILE_COL*`CHO*`CHI*(`PEA33_ROW+`PEA33_COL-1)*(`TILE_LEN+2)
`define WGT_LEN `TILE_ROW*`TILE_COL*`CHO*`CHI*3*3

