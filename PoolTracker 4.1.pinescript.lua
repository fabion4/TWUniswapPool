//@version=6
indicator("FC - Pool Tracker 4.1 (Refactored-Gemini Pro - v12 Final Final Fixed)", overlay=true)

//------------------------------------------------------------------------------
// 1. DEFINIZIONE DEL TIPO DI DATO PERSONALIZZATO PER UNA POOL
//------------------------------------------------------------------------------
type Pool
    bool    show_pool    // Un interruttore per mostrare o nascondere la pool
    int     open_time    // Data e ora di apertura (timestamp)
    int     close_time   // Data e ora di chiusura (timestamp)
    float   high_val     // Valore massimo della pool (Pb)
    float   low_val      // Valore minimo della pool (Pa)
    color   pool_color   // Colore per le linee e le etichette
    string  label_type   // Tipo di etichetta da mostrare ("span" o "default")
    float   initamt_val  // Valore iniziale depositato (V0)
    float   initial_price // Prezzo al momento del deposito (P_deposit) - crucial for L calculation
    float   liquidity    // Calcolata Liquidity L (calcolata una volta dal V0 e P_deposit)

//------------------------------------------------------------------------------
// 2. INPUT DI CONFIGURAZIONE
//------------------------------------------------------------------------------
// ---- Pool 1 ----
show_p1          = true        // Mostra Pool 1
p1_open          = timestamp("2025-06-05 18:00")   // Apertura Pool 1
p1_close         = timestamp("2025-06-09 21:40")   // Chiusura Pool 1
p1_high          = 2630.71     // Valore Massimo Pool 1
p1_low           = 2440.63     // Valore Minimo Pool 1
p1_color         = color.blue  // Colore Pool 1
p1_initamt       = 970.00      // V0 Iniziale Pool 1 (USDC)
p1_initial_price = 2500.00     // Prezzo Iniziale Deposito Pool 1

// ---- Pool 2 ----
show_p2          = true        // Mostra Pool 2
p2_open          = timestamp("2025-06-18 18:21")   // Apertura Pool 2
p2_close         = timestamp("2025-06-18 21:30")   // Chiusura Pool 2
p2_high          = 2537        // Valore Massimo Pool 2
p2_low           = 2470        // Valore Minimo Pool 2
p2_color         = color.rgb(9, 94, 37)  // Colore Pool 2
p2_initamt       = 958.78      // V0 Iniziale Pool 2 (USDC)
p2_initial_price = 2490        // Prezzo Iniziale Deposito Pool 2

// ---- Pool 3 ----
show_p3          = true        // Mostra Pool 3
p3_open          = timestamp("2025-06-19 15:38")   // Apertura Pool 3
p3_close         = timestamp("2025-06-19 21:18")   // Chiusura Pool 3
p3_high          = 2545.32     // Valore Massimo Pool 3
p3_low           = 2497.42      // Valore Minimo Pool 3
p3_color         = color.rgb(187, 53, 12)  // Colore Pool 3
p3_initamt       = 996.32         // V0 Iniziale Pool 3 (USDC)
p3_initial_price = 2500         // Prezzo Iniziale Deposito Pool 3

// ---- Pool 4 ----
show_p4          = true        // Mostra Pool 4
p4_open          = timestamp("2025-06-17 16:00")   // Apertura Pool 4
p4_close         = timestamp("2025-06-17 23:00")   // Chiusura Pool 4
p4_high          = 2503.0      // Valore Massimo Pool 4
p4_low           = 2413.0      // Valore Minimo Pool 4
p4_color         = color.orange // Colore Pool 4
p4_initamt       = 877.5       // V0 Iniziale Pool 4 (USDC)
p4_initial_price = 2500.00     // Prezzo Iniziale Deposito Pool 4

// ---- Pool 5 ----
show_p5          = true        // Mostra Pool 5
p5_open          = timestamp("2025-06-16 16:00")   // Apertura Pool 5
p5_close         = timestamp("2025-06-16 20:59")   // Chiusura Pool 5
p5_high          = 2670.0      // Valore Massimo Pool 5
p5_low           = 2630.0      // Valore Minimo Pool 5
p5_color         = color.rgb(23, 196, 52)  // Colore Pool 5
p5_initamt       = 942.0       // V0 Iniziale Pool 5 (USDC)
p5_initial_price = 2650.00     // Prezzo Iniziale Deposito
//------------------------------------------------------------------------------
// 3. FUNZIONI DI CALCOLO LIQUIDITÀ E VALORE ATTUALE
//------------------------------------------------------------------------------

calculateLiquidity(V0, Pa, Pb, P_deposit) =>
    float L = 0.0
    if V0 == 0.0 or P_deposit <= 0.0
        0.0
    else if P_deposit <= Pa
        L := V0 / ((1 / math.sqrt(Pa)) - (1 / math.sqrt(Pb))) / Pa
    else if P_deposit >= Pb
        L := V0 / (math.sqrt(Pb) - math.sqrt(Pa))
    else // Pa < P_deposit < Pb
        L := V0 / (((1 / math.sqrt(P_deposit)) - (1 / math.sqrt(Pb))) * P_deposit + (math.sqrt(P_deposit) - math.sqrt(Pa)))
    L

// Funzione per calcolare UN SINGOLO valore della pool (total value, amount0, or amount1).
// Ritorna un float.
calculateActualPoolComponent(L, Pa, Pb, P_current, return_type) =>
    float result = 0.0 // Default return value

    if L == 0.0 or Pa <= 0 or Pb <= 0 or Pa >= Pb or P_current <= 0
        // Return 0 for invalid inputs or zero liquidity
        result
    else
        float amount0_USDC = 0.0
        float amount1_ETH = 0.0

        float current_price_sqrt = math.sqrt(P_current)
        float pa_sqrt = math.sqrt(Pa)
        float pb_sqrt = math.sqrt(Pb)

        if P_current <= Pa
            amount0_USDC := L * (1 / pa_sqrt - 1 / pb_sqrt)
            amount1_ETH := 0.0
        else if P_current >= Pb
            amount0_USDC := 0.0
            amount1_ETH := L * (pb_sqrt - pa_sqrt)
        else // Pa < P_current < Pb, both tokens exist
            amount0_USDC := L * (current_price_sqrt - pa_sqrt)
            amount1_ETH :=  L * (1 / current_price_sqrt - 1 / pb_sqrt)
        
        // Return the requested component
        if return_type == "value"
            result := amount0_USDC + (amount1_ETH * P_current)
        else if return_type == "amount0_USDC"
            result := amount0_USDC
        else if return_type == "amount1_ETH"
            result := amount1_ETH
        
        result // Return the calculated component

//------------------------------------------------------------------------------
// 4. CREAZIONE DELL'ARRAY DI POOL
//------------------------------------------------------------------------------
var pools = array.new<Pool>()
if (bar_index == 0)
    float L_p1 = calculateLiquidity(p1_initamt, p1_low, p1_high, p1_initial_price)
    array.push(pools, Pool.new(show_p1, p1_open, p1_close, p1_high, p1_low, p1_color, "span", p1_initamt, p1_initial_price, L_p1))
    
    float L_p2 = calculateLiquidity(p2_initamt, p2_low, p2_high, p2_initial_price)
    array.push(pools, Pool.new(show_p2, p2_open, p2_close, p2_high, p2_low, p2_color, "span", p2_initamt, p2_initial_price, L_p2))
    
    float L_p3 = calculateLiquidity(p3_initamt, p3_low, p3_high, p3_initial_price)
    array.push(pools, Pool.new(show_p3, p3_open, p3_close, p3_high, p3_low, p3_color, "span", p3_initamt, p3_initial_price, L_p3))
    
    float L_p4 = calculateLiquidity(p4_initamt, p4_low, p4_high, p4_initial_price)
    array.push(pools, Pool.new(show_p4, p4_open, p4_close, p4_high, p4_low, p4_color, "span", p4_initamt, p4_initial_price, L_p4))
    
    float L_p5 = calculateLiquidity(p5_initamt, p5_low, p5_high, p5_initial_price)
    array.push(pools, Pool.new(show_p5, p5_open, p5_close, p5_high, p5_low, p4_color, "span", p5_initamt, p5_initial_price, L_p5))
    

//------------------------------------------------------------------------------
// 5. LOGICA DI DISEGNO CON CICLO 'FOR'
//------------------------------------------------------------------------------
if (barstate.islast)
    for i = 0 to array.size(pools) - 1
        pool = array.get(pools, i)

        if pool.show_pool
            float current_liquidity = pool.liquidity 
            
            // Initialize display variables for the current loop iteration
            // They will hold 0.0 if close <= 0 or if L is 0, or if range is invalid.
            float actual_value_for_label  = 0.0
            float amount0_USDC_for_label  = 0.0
            float amount1_ETH_for_label   = 0.0
            
            // Call the function for each specific component.
            // No shadowing warnings here because `calculateActualPoolComponent` returns a single float.
            actual_value_for_label  := calculateActualPoolComponent(current_liquidity, pool.low_val, pool.high_val, close, "value")
            amount0_USDC_for_label  := calculateActualPoolComponent(current_liquidity, pool.low_val, pool.high_val, close, "amount0_USDC")
            amount1_ETH_for_label   := calculateActualPoolComponent(current_liquidity, pool.low_val, pool.high_val, close, "amount1_ETH")
            
            // Disegniamo le linee del range della pool
            line.new(x1=pool.open_time, y1=pool.high_val, x2=pool.close_time, y2=pool.high_val, color=pool.pool_color, width=1, xloc=xloc.bar_time)
            line.new(x1=pool.open_time, y1=pool.low_val, x2=pool.close_time, y2=pool.low_val, color=pool.pool_color, width=1, xloc=xloc.bar_time)
            
            // Prepariamo il testo per l'etichetta in base al tipo specificato
            string label_text = "" 
            if pool.label_type == "span"
                span = (pool.high_val / pool.low_val - 1) * 100
                label_text := "span (" + str.tostring(pool.initamt_val, "0.00'$'") + ") " + str.tostring(span, "0.00'%'") +
                              "\nL: " + str.tostring(current_liquidity, "0.00") +
                              "\nVal: " + str.tostring(actual_value_for_label, "0.00'$'") +
                              "\nUSDC: " + str.tostring(amount0_USDC_for_label, "0.00'$'") +
                              "\nETH: " + str.tostring(amount1_ETH_for_label, "0.000") + " (" + str.tostring(amount1_ETH_for_label * close, "0.00'$'") + ")"
            else
                pool_center = (pool.high_val + pool.low_val) / 2
                percent_diff = (close - pool_center) / pool_center
                label_text := str.tostring(pool.high_val, "0.00") + " (" + str.tostring(percent_diff, format.percent) + ")" +
                              "\nL: " + str.tostring(current_liquidity, "0.00") +
                              "\nVal: " + str.tostring(actual_value_for_label, "0.00'$'") +
                              "\nUSDC: " + str.tostring(amount0_USDC_for_label, "0.00'$'") +
                              "\nETH: " + str.tostring(amount1_ETH_for_label, "0.000") + " (" + str.tostring(amount1_ETH_for_label * close, "0.00'$'") + ")"

            // Creiamo l'etichetta sul grafico
            label.new(x=pool.open_time, y=pool.high_val, text=label_text, color=pool.pool_color, textcolor=color.white, style=label.style_label_down, size=size.small, xloc=xloc.bar_time)