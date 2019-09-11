library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FiveStagePipeline is
  Port (
        CLK  : in std_logic;
        PC   : out std_logic_vector(31 downto 0); 
        I    : out std_logic_vector(31 downto 0);
        Data : out std_logic_vector(31 downto 0)
        );
end FiveStagePipeline;

architecture Structural of FiveStagePipeline is

    component InstructionFetch
        Port ( 
               CLK          : in std_logic;
               StageEnable  : in std_logic;
               PCLoadEnable : in std_logic;
               PCLoadValue  : in std_logic_vector(31 downto 0);
               Instruction  : out std_logic_vector(31 downto 0);
               PCLink		: out std_logic_vector(31 downto 0);
               PCCurrValue  : out std_logic_vector(31 downto 0)
             );
    end component;
    
    component IFID_Stage_Registers
        Port ( 
               CLK    :     in STD_LOGIC;
               Enable :     in STD_LOGIC;
               IF_PC  :     in STD_LOGIC_VECTOR (31 downto 0);
               IF_I   :     in STD_LOGIC_VECTOR (31 downto 0);
               IF_PCLink :  in std_logic_vector(31 downto 0);
               ID_PC  :     out STD_LOGIC_VECTOR (31 downto 0);
               ID_PCLink :  out std_logic_vector(31 downto 0);
               ID_I   :     out STD_LOGIC_VECTOR (31 downto 0));
    end component;
    
    component InstructionDecode
        Port ( Instruction : in STD_LOGIC_VECTOR (31 downto 0);
               -- Data dependency control inputs
               EX_DA : in STD_LOGIC_VECTOR ( 3 downto 0);
               MEM_DA : in STD_LOGIC_VECTOR ( 3 downto 0);
               WB_DA : in STD_LOGIC_VECTOR ( 3 downto 0);
               EX_MD  : in STD_LOGIC_VECTOR( 1 downto 0);
               MEM_MD : in STD_LOGIC_VECTOR( 1 downto 0);
               -- Control dependency control inputs
               PL_EX    : in STD_LOGIC_VECTOR ( 1 downto 0);
               EX_Jump_Flag : in std_logic;
                -- Instruction operands (OF => Operand Fetch)
               AA       : out STD_LOGIC_VECTOR ( 3 downto 0);
               MA       : out STD_LOGIC_VECTOR(1 downto 0);
               BA       : out STD_LOGIC_VECTOR ( 3 downto 0);
               MB       : out STD_LOGIC_VECTOR(1 downto 0);
               KNS      : out STD_LOGIC_VECTOR (31 downto 0);
               SEL_B    : out STD_LOGIC;
               -- execution control (EX => Execute)
               FS       : out STD_LOGIC_VECTOR ( 3 downto 0);
               PL       : out STD_LOGIC_VECTOR ( 1 downto 0);
               BC       : out STD_LOGIC_VECTOR ( 3 downto 0);
               -- memory control (MEM => Memory)
               MMA      : out STD_LOGIC_VECTOR ( 1 downto 0);
               MMB      : out STD_LOGIC_VECTOR ( 1 downto 0);
               MW       : out STD_LOGIC;
                -- Instruction Result (WB => Write-Back)
               MD       : out STD_LOGIC_VECTOR ( 1 downto 0);
               DA       : out STD_LOGIC_VECTOR ( 3 downto 0);
                -- For banch control block
               c_WB_regA : out std_logic;
               c_WB_regB : out std_logic;
               -- Data dependency control inputs
               STALL_CLK    : out STD_LOGIC;
               STALL_REG    : out STD_LOGIC
              );
    end component;
    
    component branchcontrol is
        Generic (n_bits : integer := 32);
        Port ( PL : in std_logic_vector(1 downto 0);
               BC : in STD_LOGIC_VECTOR(3 downto 0);
               PC : in STD_LOGIC_VECTOR (31 downto 0);
               PC_Link : in STD_LOGIC_VECTOR (31 downto 0);
               EX_PC_Link : in STD_LOGIC_VECTOR (31 downto 0);
               MA :     in STD_LOGIC_VECTOR(1 downto 0);
               MB :     in STD_LOGIC_VECTOR(1 downto 0);
               SEL_B :  in STD_LOGIC;
               A      : in std_logic_vector(n_bits-1 downto 0); 
               B      : in std_logic_vector(n_bits-1 downto 0);
               KNS    : in std_logic_vector(n_bits-1 downto 0); 
               ALU_data : in std_logic_vector(31 downto 0);
               MEM_data:  in std_logic_vector(31 downto 0);
               c_WB_regA : in std_logic;
               c_WB_regB : in std_logic;
               STALL_REG_IN : in std_logic;
               DA_IN       :   in STD_LOGIC_VECTOR ( 3 downto 0);
               MEM_Jump_Flag : in std_logic;
               PL_EX : in STD_LOGIC_VECTOR(1 downto 0);
               BC_EX : in STD_LOGIC_VECTOR(3 downto 0);
               BA    : in STD_LOGIC_VECTOR(3 downto 0);
               PCLoad : out STD_LOGIC;
               Jump_Flag : out std_logic;
               STALL_REG_OUT : out std_logic;
               DA_OUT       :   out STD_LOGIC_VECTOR ( 3 downto 0);
               PCValue : out STD_LOGIC_VECTOR (31 downto 0));
    end component;
    
    component IDEX_Stage_Registers
        Port ( 
            CLK    : in STD_LOGIC;
            Enable : in STD_LOGIC;
            ID_PC  : in STD_LOGIC_VECTOR (31 downto 0);
            ID_I   : in STD_LOGIC_VECTOR (31 downto 0);
            ID_A   : in STD_LOGIC_VECTOR (31 downto 0);
            ID_B   : in STD_LOGIC_VECTOR (31 downto 0);
            ID_KNS : in STD_LOGIC_VECTOR (31 downto 0);
            ID_MA  : in STD_LOGIC_VECTOR(1 downto 0);
            ID_MB  : in STD_LOGIC_VECTOR(1 downto 0);
            ID_SEL_B  : in STD_LOGIC;
            ID_FS  : in STD_LOGIC_VECTOR (3 downto 0);
            ID_MMA : in STD_LOGIC_VECTOR (1 downto 0);
            ID_MMB : in STD_LOGIC_VECTOR (1 downto 0);
            ID_MW  : in STD_LOGIC;
            ID_MD  : in STD_LOGIC_VECTOR ( 1 downto 0);
            ID_DA  : in STD_LOGIC_VECTOR (3 downto 0);
            ID_PCLink :  in std_logic_vector(31 downto 0);
            ID_Jump_Flag : in std_logic;
            ID_PL  : in STD_LOGIC_VECTOR ( 1 downto 0);
            ID_BC  : in STD_LOGIC_VECTOR (3 downto 0);
            EX_PC  : out STD_LOGIC_VECTOR (31 downto 0);
            EX_I   : out STD_LOGIC_VECTOR (31 downto 0);
            EX_A   : out STD_LOGIC_VECTOR (31 downto 0);
            EX_B   : out STD_LOGIC_VECTOR (31 downto 0);
            EX_KNS : out STD_LOGIC_VECTOR (31 downto 0);
            EX_MA  : out STD_LOGIC_VECTOR(1 downto 0);
            EX_MB  : out STD_LOGIC_VECTOR(1 downto 0);
            EX_SEL_B  : out STD_LOGIC;
            EX_FS  : out STD_LOGIC_VECTOR (3 downto 0);
            EX_MMA : out STD_LOGIC_VECTOR (1 downto 0);
            EX_MMB : out STD_LOGIC_VECTOR (1 downto 0);
            EX_MW  : out STD_LOGIC;
            EX_MD  : out STD_LOGIC_VECTOR ( 1 downto 0);
            EX_DA  : out STD_LOGIC_VECTOR (3 downto 0);
            EX_Jump_Flag : out std_logic;
            EX_BC  : out STD_LOGIC_VECTOR (3 downto 0);
            EX_PL : out STD_LOGIC_VECTOR ( 1 downto 0);
            EX_PCLink :  out std_logic_vector(31 downto 0)
           );
    end component;
    
    component Execute
      Port (
        A      : in std_logic_vector(31 downto 0); 
        B      : in std_logic_vector(31 downto 0);
        MA     : in STD_LOGIC_VECTOR(1 downto 0);
        MB     : in STD_LOGIC_VECTOR(1 downto 0);
        EX_SEL_B  : in STD_LOGIC;
        KNS    : in std_logic_vector(31 downto 0); 
        FS     : in std_logic_vector( 3 downto 0);
        ALU_data : in std_logic_vector(31 downto 0);
        MEM_data:  in std_logic_vector(31 downto 0);
        MemD   : out std_logic_vector(31 downto 0);
        DataD  : out std_logic_vector(31 downto 0) 
      );
    end component;
    
    component EXMEM_Stage_Registers
        Port ( 
            CLK     : in STD_LOGIC;
            Enable  : in STD_LOGIC;
            EX_PC   : in STD_LOGIC_VECTOR (31 downto 0);
            EX_I    : in STD_LOGIC_VECTOR (31 downto 0);
            EX_A    : in STD_LOGIC_VECTOR (31 downto 0);
            EX_B    : in STD_LOGIC_VECTOR (31 downto 0);
            EX_D    : in STD_LOGIC_VECTOR (31 downto 0);
            EX_KNS  : in STD_LOGIC_VECTOR (31 downto 0);
            EX_MMA  : in STD_LOGIC_VECTOR (1 downto 0);
            EX_MMB  : in STD_LOGIC_VECTOR (1 downto 0);
            EX_MW   : in STD_LOGIC;
            EX_MD   : in STD_LOGIC_VECTOR ( 1 downto 0);
            EX_DA   : in STD_LOGIC_VECTOR (3 downto 0);
            EX_PCLink :  in std_logic_vector(31 downto 0);
            EX_MemD   : in std_logic_vector(31 downto 0);
            EX_BC  : in STD_LOGIC_VECTOR (3 downto 0);
            EX_PL :  in STD_LOGIC_VECTOR ( 1 downto 0);
            EX_Jump_Flag : in std_logic;
            MEM_Jump_Flag : out std_logic;
            MEM_BC  : out STD_LOGIC_VECTOR (3 downto 0);
            MEM_PL :  out STD_LOGIC_VECTOR ( 1 downto 0);
            MEM_PC  : out STD_LOGIC_VECTOR (31 downto 0);
            MEM_I   : out STD_LOGIC_VECTOR (31 downto 0);
            MEM_A   : out STD_LOGIC_VECTOR (31 downto 0);
            MEM_B   : out STD_LOGIC_VECTOR (31 downto 0);
            MEM_D   : out STD_LOGIC_VECTOR (31 downto 0);
            MEM_KNS : out STD_LOGIC_VECTOR (31 downto 0);
            MEM_MMA : out STD_LOGIC_VECTOR (1 downto 0);
            MEM_MMB : out STD_LOGIC_VECTOR (1 downto 0);
            MEM_MW  : out STD_LOGIC;
            MEM_MD  : out STD_LOGIC_VECTOR ( 1 downto 0);
            MEM_DA  : out STD_LOGIC_VECTOR (3 downto 0);
            MEM_MemD   : out std_logic_vector(31 downto 0);
            MEM_PCLink :  out std_logic_vector(31 downto 0)
        );
    end component;
    
    component Memory is
      Port (
        CLK   : in std_logic;
        StageEnable: in std_logic;
        A     : in std_logic_vector(31 downto 0); 
        B     : in std_logic_vector(31 downto 0);
        KNS   : in std_logic_vector(31 downto 0);
        Din   : in std_logic_vector(31 downto 0);
        MMA   : in std_logic_vector( 1 downto 0);
        MMB   : in std_logic_vector( 1 downto 0);
        MW    : in std_logic;
        Dout  : out std_logic_vector(31 downto 0)
      );
    end component;
    
    component MEMWB_Stage_Registers
        Port ( 
            CLK      : in STD_LOGIC;
            Enable   : in STD_LOGIC;
            MEM_PC   : in STD_LOGIC_VECTOR (31 downto 0);
            MEM_I    : in STD_LOGIC_VECTOR (31 downto 0);
            MEM_DMem : in STD_LOGIC_VECTOR (31 downto 0);
            MEM_DALU : in STD_LOGIC_VECTOR (31 downto 0);
            MEM_MD   : in STD_LOGIC_VECTOR ( 1 downto 0);
            MEM_DA   : in STD_LOGIC_VECTOR (3 downto 0);
            MEM_PCLink :  in std_logic_vector(31 downto 0);
            WB_PC    : out STD_LOGIC_VECTOR (31 downto 0);
            WB_I     : out STD_LOGIC_VECTOR (31 downto 0);
            WB_DMem  : out STD_LOGIC_VECTOR (31 downto 0);
            WB_DALU  : out STD_LOGIC_VECTOR (31 downto 0);
            WB_MD    : out STD_LOGIC_VECTOR ( 1 downto 0);
            WB_DA    : out STD_LOGIC_VECTOR (3 downto 0);
            WB_PCLink :  out std_logic_vector(31 downto 0)
        );
    end component;
    
    component WriteBack
      Port (
            Enable   : in STD_LOGIC;
            DA       : in STD_LOGIC_VECTOR(3 downto 0);
            MD       : in STD_LOGIC_VECTOR ( 1 downto 0);
            ALUData  : in STD_LOGIC_VECTOR(31 downto 0);
            MemData  : in STD_LOGIC_VECTOR(31 downto 0);
            PC 		 : in STD_LOGIC_VECTOR(31 downto 0);
            RFData   : out STD_LOGIC_VECTOR(31 downto 0)
            );
    end component;
    
    component RegisterFile
        Generic (n_bits : natural := 32);
        Port ( CLK : in std_logic;
               Data : in std_logic_vector (n_bits-1 downto 0);
               DA : in std_logic_vector (3 downto 0);
               AA : in std_logic_vector (3 downto 0);
               BA : in std_logic_vector (3 downto 0);
               A : out std_logic_vector (n_bits-1 downto 0);
               B : out std_logic_vector (n_bits-1 downto 0));
    end component;
    
    signal EnableIF, EnableID, EnableEX, EnableMEM, EnableWB, EnableCLK : std_logic;
    
    -- Extra signals
    signal IF_PCLink_s, ID_PCLink_s, EX_PCLink_s, MEM_PCLink_s, WB_PCLink_s : std_logic_vector(31 downto 0);
    signal ID_Jump_Flag, EX_Jump_Flag, MEM_Jump_Flag : std_logic;
    signal EX_MemD, MEM_MemD : std_logic_vector(31 downto 0);
    signal c_WB_regA, c_WB_regB : std_logic;
    signal STALL_REG_IN, AND9 : std_logic;
    signal DA_IN : std_logic_vector(3 downto 0);
    
    -- Instruction & PC signals
    signal IF_Instruction, ID_Instruction, EX_Instruction, MEM_Instruction, WB_Instruction : std_logic_vector(31 downto 0);
    signal IF_PC, ID_PC, EX_PC, MEM_PC, WB_PC : std_logic_vector(31 downto 0);
    signal ID_BC, EX_BC, MEM_BC : std_logic_vector(3 downto 0);
    signal EX_PCLoadEnable : std_logic;
    signal EX_PCLoadValue : std_logic_vector(31 downto 0);
    signal ID_PL, EX_PL, MEM_PL : STD_LOGIC_VECTOR ( 1 downto 0);
    
    -- RF addressing and operand selection signals
    signal ID_AA, ID_BA, ID_DA, EX_DA, MEM_DA, WB_DA : std_logic_vector(3 downto 0);
    signal ID_MA, EX_MA, ID_MB, EX_MB : STD_LOGIC_VECTOR(1 downto 0);
    signal ID_MMA, EX_MMA, MEM_MMA, ID_MMB, EX_MMB, MEM_MMB : std_logic_vector(1 downto 0);
    signal ID_MD, EX_MD, MEM_MD, WB_MD : STD_LOGIC_VECTOR ( 1 downto 0);
    signal ID_SEL_B, EX_SEL_B : std_logic;
    
    -- Functional Unit and Memory Operation Signals
    signal ID_FS, EX_FS : std_logic_vector(3 downto 0);
    signal ID_MW, EX_MW, MEM_MW : std_logic;
    
    -- Data Signals
    signal ID_KNS, EX_KNS, MEM_KNS : std_logic_vector(31 downto 0);
    signal ID_A, EX_A, MEM_A: std_logic_vector(31 downto 0);
    signal ID_B, EX_B, MEM_B: std_logic_vector(31 downto 0);
    signal EX_ALUData, MEM_ALUData, WB_ALUData: std_logic_vector(31 downto 0);
    signal MEM_MemData, WB_MemData: std_logic_vector(31 downto 0);
    signal WB_RFData: std_logic_vector(31 downto 0);

begin

    EnableID<='1';
    EnableEX<='1';
    EnableMEM<='1';
    EnableWB<='1';
    
    --------------------------------------------------------------------------------------------------------------------------
    -- IF Stage
    --------------------------------------------------------------------------------------------------------------------------
    -- Instruction Fetch (IF) Stage Logic
    IFetch: InstructionFetch port map(
        CLK => CLK, 
        StageEnable => EnableCLK,
        PCLoadEnable => EX_PCLoadEnable,
        PCLoadValue => EX_PCLoadValue,  
        Instruction => IF_Instruction,
        PCLink => IF_PCLink_s,
        PCCurrValue => IF_PC);
    
    -- Registers between IF and ID Stage
    IF2ID: IFID_Stage_Registers port map(
        CLK => CLK, 
        Enable => EnableIF, 
        IF_PC => IF_PC, 
        IF_I => IF_Instruction,
        IF_PCLink => IF_PCLink_s,
        ID_PC => ID_PC,
        ID_PCLink => ID_PCLink_s,
        ID_I => ID_Instruction);
    
    --------------------------------------------------------------------------------------------------------------------------
    -- ID Stage
    --------------------------------------------------------------------------------------------------------------------------
    -- Instruction Decode (ID) Stage
    ID: InstructionDecode port map(
        Instruction => ID_Instruction,
        EX_DA => EX_DA,
        MEM_DA => MEM_DA,
        WB_DA => WB_DA,
        PL_EX => EX_PL,
        EX_Jump_Flag => EX_Jump_Flag,
        EX_MD => EX_MD,
        MEM_MD => MEM_MD,
        AA => ID_AA, 
        MA => ID_MA, 
        BA => ID_BA, 
        MB => ID_MB, 
        SEL_B => ID_SEL_B,
        KNS => ID_KNS, 
        FS => ID_FS, 
        PL => ID_PL, 
        BC => ID_BC, 
        MMA => ID_MMA, 
        MMB => ID_MMB, 
        MW => ID_MW, 
        MD => ID_MD, 
        DA => DA_IN,
        c_WB_regA => c_WB_regA,
        c_WB_regB => c_WB_regB,
        STALL_CLK => EnableCLK,
        STALL_REG => STALL_REG_IN);
        
    UCS: branchcontrol port map(
        PL => ID_PL, 
        BC => ID_BC, 
        PC => ID_PC, 
        PC_Link => IF_PCLink_s,
        EX_PC_Link => EX_PCLink_s,
        MA => ID_MA,
        MB => ID_MB, 
        SEL_B => ID_SEL_B,
        A => ID_A,
        B => ID_B,
        KNS => ID_KNS,
        ALU_data => MEM_ALUData,
        MEM_data => WB_RFData,
        c_WB_regA => c_WB_regA,
        c_WB_regB => c_WB_regB,
        STALL_REG_IN => STALL_REG_IN,
        DA_IN => DA_IN,
        MEM_Jump_Flag => MEM_Jump_Flag,
        PL_EX => MEM_PL,
        BA => ID_BA,
        BC_EX => MEM_BC,
        Jump_Flag => ID_Jump_Flag,
        PCLoad => EX_PCLoadEnable, 
        STALL_REG_OUT => EnableIF,
        DA_OUT => ID_DA,
        PCValue => EX_PCLoadValue
    );        
    
    -- Registers between ID and EX Stage
    ID2EX: IDEX_Stage_Registers port map(
        CLK => CLK, 
        Enable => EnableID, 
        ID_I => ID_Instruction, 
        ID_PC => ID_PC, 
        ID_A => ID_A, 
        ID_B => ID_B, 
        ID_KNS => ID_KNS, 
        ID_MA => ID_MA, 
        ID_MB => ID_MB,
        ID_SEL_B => ID_SEL_B,
        ID_MMA => ID_MMA, 
        ID_MMB => ID_MMB, 
        ID_MW => ID_MW, 
        ID_FS => ID_FS, 
        ID_MD => ID_MD, 
        ID_DA => ID_DA,
        ID_PL => ID_PL,
        ID_PCLink => ID_PCLink_s,
        ID_Jump_Flag => ID_Jump_Flag,
        ID_BC => ID_BC,
        EX_I => EX_Instruction, 
        EX_PC => EX_PC, 
        EX_A => EX_A, 
        EX_B => EX_B, 
        EX_KNS => EX_KNS, 
        EX_MA => EX_MA, 
        EX_MB => EX_MB,
        EX_SEL_B => EX_SEL_B,
        EX_MMA => EX_MMA, 
        EX_MMB => EX_MMB, 
        EX_MW => EX_MW, 
        EX_FS => EX_FS, 
        EX_MD => EX_MD, 
        EX_DA => EX_DA,
        EX_Jump_Flag => EX_Jump_Flag,
        EX_PL => EX_PL,
        EX_BC => EX_BC,
        EX_PCLink => EX_PCLink_s
    );
    
    --------------------------------------------------------------------------------------------------------------------------
    -- EX Stage
    --------------------------------------------------------------------------------------------------------------------------
    EX: Execute port map(
        A => EX_A, 
        B => EX_B, 
        MA => EX_MA, 
        MB => EX_MB, 
        EX_SEL_B => EX_SEL_B,
        KNS => EX_KNS, 
        FS => EX_FS, 
        ALU_data => MEM_ALUData,
        MEM_data => WB_RFData,
        MemD => EX_MemD,
        DataD => EX_ALUData);
    
    -- Registers between EX and MEM Stage
    EX2MEM: EXMEM_Stage_Registers port map(
        CLK => CLK, 
        Enable => EnableEX, 
         EX_I => EX_Instruction,   
         EX_PC => EX_PC,   
         EX_A => EX_A,   
         EX_B => EX_B,   
         EX_KNS => EX_KNS,   
         EX_D => EX_ALUData,   
         EX_MMA => EX_MMA,   
         EX_MMB => EX_MMB,   
         EX_MW => EX_MW,   
         EX_MD => EX_MD,   
         EX_DA => EX_DA,
         EX_PCLink => EX_PCLink_s,
         EX_MemD => EX_MemD,
         EX_BC => EX_BC,
         EX_PL => EX_PL,
         EX_Jump_Flag => EX_Jump_Flag,
         MEM_BC => MEM_BC,
         MEM_PL => MEM_PL,
         MEM_Jump_Flag => MEM_Jump_Flag,
         MEM_I => MEM_Instruction, 
         MEM_PC => MEM_PC, 
         MEM_A => MEM_A, 
         MEM_B => MEM_B, 
         MEM_KNS => MEM_KNS, 
         MEM_D => MEM_ALUData, 
         MEM_MMA => MEM_MMA, 
         MEM_MMB => MEM_MMB, 
         MEM_MW => MEM_MW, 
         MEM_MD => MEM_MD, 
         MEM_DA => MEM_DA,
         MEM_MemD => MEM_MemD,
         MEM_PCLink => MEM_PCLink_s
         );
    
    --------------------------------------------------------------------------------------------------------------------------
    -- MEM Stage
    --------------------------------------------------------------------------------------------------------------------------
    MEM: Memory port map(
        CLK => CLK, 
        StageEnable => EnableMEM, 
        A => MEM_A, 
        B => MEM_MemD, 
        Din => MEM_ALUData, 
        KNS => MEM_KNS, 
        MMA => MEM_MMA, 
        MMB => MEM_MMB, 
        MW => MEM_MW, 
        Dout => MEM_MemData);
    -- Registers between MEM and WB Stage
    
    MEM2WB: MEMWB_Stage_Registers port map(
        CLK => CLK, 
        Enable => EnableMEM, 
        MEM_I => MEM_Instruction, 
        MEM_PC => MEM_PC, 
        MEM_DALU => MEM_ALUData, 
        MEM_DMem => MEM_MemData, 
        MEM_MD => MEM_MD, 
        MEM_DA => MEM_DA,
        MEM_PCLink => MEM_PCLink_s,
        WB_I => WB_Instruction,   
        WB_PC => WB_PC,   
        WB_DALU => WB_ALUData,   
        WB_DMem => WB_MemData,   
        WB_MD => WB_MD,   
        WB_DA => WB_DA,
        WB_PCLink => WB_PCLink_s);
    
    --------------------------------------------------------------------------------------------------------------------------
    -- WB Stage
    --------------------------------------------------------------------------------------------------------------------------
    WB: WriteBack port map(
        enable => enableWB, 
        DA => WB_DA, 
        MD => WB_MD, 
        ALUData => WB_ALUData, 
        MemData => WB_MemData,
        PC => WB_PCLink_s,
        RFData => WB_RFData);
    
    --------------------------------------------------------------------------------------------------------------------------
    -- Register File
    --------------------------------------------------------------------------------------------------------------------------
    RF: RegisterFile generic map(n_bits=>32) port map(CLK=>CLK, Data=>WB_RFData, DA=>WB_DA, AA=>ID_AA, BA=>ID_BA, A=>ID_A, B=>ID_B); 
    
    --------------------------------------------------------------------------------------------------------------------------
    -- Output
    --------------------------------------------------------------------------------------------------------------------------
    Data<=WB_RFData;
    I<=ID_Instruction;
    PC<=ID_PC;

end Structural;