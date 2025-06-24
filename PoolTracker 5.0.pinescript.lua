//@version=6
indicator("FC - Pool Tracker 5.0 (Refactored-Gemini Pro - Confirmed Token Logic)", overlay=true)

//------------------------------------------------------------------------------
// 1. CUSTOM DATA TYPE DEFINITION FOR A POOL
//------------------------------------------------------------------------------
type Pool
    bool    show_pool           // A switch to show or hide the pool
    int     open_time           // Opening date and time (timestamp)
    int     close_time          // Closing date and time (timestamp)
    float   high_val            // Maximum pool value (Pb)
    float   low_val             // Minimum pool value (Pa)
    color   pool_color          // Color for lines and labels
    string  label_type          // Type of label to show ("span" or "default")
    float   initamt_val         // Initial deposited value (V0)
    float   initial_price       // Price at the time of deposit (P_deposit) - crucial for L calculation
    float   liquidity           // Calculated Liquidity L (calculated once from V0 and P_deposit)
    // Add references to drawing objects to manage them
    line    line_high_ref       // Reference to the high line object
    line    line_low_ref        // Reference to the low line object
    label   label_info_ref      // Reference to the main info label object
    label   label_initial_price_ref // Reference to the initial price marker label

//------------------------------------------------------------------------------
// 2. INPUT OF CONFIGURATION
//------------------------------------------------------------------------------
// ---- Pool 1 ----
show_p1          = true          // Show Pool 1
p1_open          = timestamp("2025-06-23 15:40")   // Pool 1 Opening
p1_close         = timestamp("2025-06-23 18:12")   // Pool 1 Closing
p1_high          = 375.62       // Pool 1 Maximum Value
p1_low           = 2239.52       // Pool 1 Minimum Value
p1_color         = color.blue    // Pool 1 Color
p1_initamt       = 941.00        // Pool 1 Initial V0 (USDC)
p1_initial_price = 2271.00       // Pool 1 Initial Deposit Price

// ---- Pool 2 ----
show_p2          = true          // Show Pool 2
p2_open          = timestamp("2025-06-18 18:21")   // Pool 2 Opening
p2_close         = timestamp("2025-06-18 21:30")   // Pool 2 Closing
p2_high          = 2537          // Pool 2 Maximum Value
p2_low           = 2470          // Pool 2 Minimum Value
p2_color         = color.rgb(9, 94, 37)  // Pool 2 Color
p2_initamt       = 958.78        // Pool 2 Initial V0 (USDC)
p2_initial_price = 2490          // Pool 2 Initial Deposit Price

// ---- Pool 3 ----
show_p3          = true          // Show Pool 3
p3_open          = timestamp("2025-06-19 15:38")   // Pool 3 Opening
p3_close         = timestamp("2025-06-19 21:18")   // Pool 3 Closing
p3_high          = 2545.32       // Pool 3 Maximum Value
p3_low           = 2497.42       // Pool 3 Minimum Value
p3_color         = color.rgb(187, 53, 12)  // Pool 3 Color
p3_initamt       = 996.32        // Pool 3 Initial V0 (USDC)
p3_initial_price = 2500          // Pool 3 Initial Deposit Price

// ---- Pool 4 ----
show_p4          = true          // Show Pool 4
p4_open          = timestamp("2025-06-17 16:00")   // Pool 4 Opening
p4_close         = timestamp("2025-06-17 23:00")   // Pool 4 Closing
p4_high          = 2503.0        // Pool 4 Maximum Value
p4_low           = 2413.0        // Pool 4 Minimum Value
p4_color         = color.orange // Pool 4 Color
p4_initamt       = 877.5         // Pool 4 Initial V0 (USDC)
p4_initial_price = 2500.00       // Pool 4 Initial Deposit Price

// ---- Pool 5 ----
show_p5          = true          // Show Pool 5
p5_open          = timestamp("2025-06-16 16:00")   // Pool 5 Opening
p5_close         = timestamp("2025-06-16 20:59")   // Pool 5 Closing
p5_high          = 2670.0        // Pool 5 Maximum Value
p5_low           = 2630.0        // Pool 5 Minimum Value
p5_color         = color.rgb(23, 196, 52)  // Pool 5 Color
p5_initamt       = 942.0         // Pool 5 Initial V0 (USDC)
p5_initial_price = 2650.00       // Initial Deposit Price
//------------------------------------------------------------------------------
// 3. LIQUIDITY AND CURRENT VALUE CALCULATION FUNCTIONS
//------------------------------------------------------------------------------

// Function to calculate liquidity (L) based on initial deposited value (V0)
// and the price at the time of deposit (P_deposit), and the pool's price range.
// **This function is using the logic that you previously confirmed produced "ok" liquidity values.**
calculateLiquidity(V0, Pa, Pb, P_deposit) =>
    float L = 0.0
    if V0 == 0.0 or P_deposit <= 0.0 or Pa <= 0 or Pb <= 0 or Pa >= Pb // Added safety checks here
        0.0 // Returns 0 for invalid inputs or zero liquidity
    else if P_deposit <= Pa
        L := V0 / ((1 / math.sqrt(Pa)) - (1 / math.sqrt(Pb))) / Pa
    else if P_deposit >= Pb
        L := V0 / (math.sqrt(Pb) - math.sqrt(Pa))
    else // Pa < P_deposit < Pb
        L := V0 / (((1 / math.sqrt(P_deposit)) - (1 / math.sqrt(Pb))) * P_deposit + (math.sqrt(P_deposit) - math.sqrt(Pa)))
    L

// Function to calculate a SINGLE component of the pool's actual value at the current price.
// Returns a float representing total value, amount0 (USDC), or amount1 (ETH).
// P_current is assumed to be Price = Token0 / Token1 (e.g., USDC / ETH).
// **The logic for token distribution at boundaries is now set to your explicitly stated requirements.**
calculateActualPoolComponent(L, Pa, Pb, P_current, return_type) =>
    float result = 0.0

    if L == 0.0 or Pa <= 0 or Pb <= 0 or Pa >= Pb or P_current <= 0
        // Return 0 for invalid inputs or zero liquidity
        result
    else
        float amount0_USDC = 0.0 // Amount of Token0 (USDC)
        float amount1_ETH = 0.0  // Amount of Token1 (ETH)

        float current_price_sqrt = math.sqrt(P_current)
        float pa_sqrt = math.sqrt(Pa)
        float pb_sqrt = math.sqrt(Pb)

        // **Implementing YOUR SPECIFIC TOKEN DISTRIBUTION LOGIC:**
        // If P_current is below or at the lower bound (Pa), the pool should primarily hold ETH.
        if P_current <= Pa
            amount0_USDC :=    0.0  
            amount1_ETH :=L * (1 / pa_sqrt - 1 / pb_sqrt) // Formula for all Token1 (ETH)
        // If P_current is above or at the upper bound (Pb), the pool should primarily hold USDC.
        else if P_current >= Pb
            amount0_USDC := L * (pb_sqrt - pa_sqrt) // Formula for all Token0 (USDC)
            amount1_ETH := 0.0
        else // Pa < P_current < Pb, both tokens exist within the range
            // These formulas remain the same as they are correct for in-range
            amount0_USDC := L * (current_price_sqrt - pa_sqrt) // Amount of Token0 (USDC) in the pool
            amount1_ETH :=    L * (1 / current_price_sqrt - 1 / pb_sqrt)     // Amount of Token1 (ETH) in the pool
        
        // Return the requested component based on 'return_type'
        if return_type == "value"
            result := amount0_USDC + (amount1_ETH * P_current) // Total value in Token0 terms
        else if return_type == "amount0_USDC"
            result := amount0_USDC // Only Token0 amount
        else if return_type == "amount1_ETH"
            result := amount1_ETH // Only Token1 amount
        
        result
//------------------------------------------------------------------------------
// 4. POOL ARRAY CREATION
//------------------------------------------------------------------------------
// 'var' keyword initializes the array once on the first bar and preserves its state.
var pools = array.new<Pool>()
if (bar_index == 0)
    // For each defined pool, calculate its initial liquidity (L) and add it to the 'pools' array.
    // Each pool is initialized with 'na' for drawing object references, which will be created later.
    float L_p1 = calculateLiquidity(p1_initamt, p1_low, p1_high, p1_initial_price)
    array.push(pools, Pool.new(show_p1, p1_open, p1_close, p1_high, p1_low, p1_color, "span", p1_initamt, p1_initial_price, L_p1, na, na, na, na))
    
    float L_p2 = calculateLiquidity(p2_initamt, p2_low, p2_high, p2_initial_price)
    array.push(pools, Pool.new(show_p2, p2_open, p2_close, p2_high, p2_low, p2_color, "span", p2_initamt, p2_initial_price, L_p2, na, na, na, na))
    
    float L_p3 = calculateLiquidity(p3_initamt, p3_low, p3_high, p3_initial_price)
    array.push(pools, Pool.new(show_p3, p3_open, p3_close, p3_high, p3_low, p3_color, "span", p3_initamt, p3_initial_price, L_p3, na, na, na, na))
    
    float L_p4 = calculateLiquidity(p4_initamt, p4_low, p4_high, p4_initial_price)
    array.push(pools, Pool.new(show_p4, p4_open, p4_close, p4_high, p4_low, p4_color, "span", p4_initamt, p4_initial_price, L_p4, na, na, na, na))
    
    // Corrected pool color for p5 here, it was accidentally p4_color before.
    float L_p5 = calculateLiquidity(p5_initamt, p5_low, p5_high, p5_initial_price)
    array.push(pools, Pool.new(show_p5, p5_open, p5_close, p5_high, p5_low, p5_color, "span", p5_initamt, p5_initial_price, L_p5, na, na, na, na)) 
    
//------------------------------------------------------------------------------
// 5. DRAWING LOGIC WITH 'FOR' LOOP
//------------------------------------------------------------------------------
// This loop runs on every bar of the chart. It iterates through each pool
// in the array and, if active, performs calculations and draws elements.
// Use 'var' to persist drawing objects across bars (for efficient updates)
var float current_liquidity_val = 0.0
var float actual_value_for_label_val = 0.0
var float amount0_USDC_for_label_val = 0.0
var float amount1_ETH_for_label_val = 0.0
var string label_text_val = ""

for i = 0 to array.size(pools) - 1
    pool = array.get(pools, i)

    if pool.show_pool
        // Calculate dynamic values for the current pool.
        current_liquidity_val := pool.liquidity 
        actual_value_for_label_val := calculateActualPoolComponent(current_liquidity_val, pool.low_val, pool.high_val, close, "value")
        amount0_USDC_for_label_val := calculateActualPoolComponent(current_liquidity_val, pool.low_val, pool.high_val, close, "amount0_USDC")
        amount1_ETH_for_label_val := calculateActualPoolComponent(current_liquidity_val, pool.low_val, pool.high_val, close, "amount1_ETH")
        
        // Prepare the text for the label based on the specified type
        if pool.label_type == "span"
            span = (pool.high_val / pool.low_val - 1) * 100
            label_text_val := "span (" + str.tostring(pool.initamt_val, "0.00'$'") + ") " + str.tostring(span, "0.00'%'") +
                          "\nL: " + str.tostring(current_liquidity_val, "0.00") +
                          "\nVal: " + str.tostring(actual_value_for_label_val, "0.00'$'") +
                          "\nUSDC: " + str.tostring(amount0_USDC_for_label_val, "0.00'$'") +
                          "\nETH: " + str.tostring(amount1_ETH_for_label_val, "0.000") + " (" + str.tostring(amount1_ETH_for_label_val * close, "0.00'$'") + ")"
        else
            pool_center = (pool.high_val + pool.low_val) / 2
            percent_diff = (close - pool_center) / pool_center
            label_text_val := str.tostring(pool.high_val, "0.00") + " (" + str.tostring(percent_diff, format.percent) + ")" +
                          "\nL: " + str.tostring(current_liquidity_val, "0.00") +
                          "\nVal: " + str.tostring(actual_value_for_label_val, "0.00'$'") +
                          "\nUSDC: " + str.tostring(amount0_USDC_for_label_val, "0.00'$'") +
                          "\nETH: " + str.tostring(amount1_ETH_for_label_val, "0.000") + " (" + str.tostring(amount1_ETH_for_label_val * close, "0.00'$'") + ")"

        // --- Drawing Logic (create/update on last bar) ---
        // We perform drawing only on the last bar for efficiency and to manage persistent objects.
        if barstate.islast
            // Create high price line if it doesn't exist, otherwise update it
            if na(pool.line_high_ref)
                pool.line_high_ref := line.new(x1=pool.open_time, y1=pool.high_val, x2=pool.close_time, y2=pool.high_val, color=pool.pool_color, width=1, xloc=xloc.bar_time)
            else
                line.set_x1(pool.line_high_ref, pool.open_time)
                line.set_y1(pool.line_high_ref, pool.high_val)
                line.set_x2(pool.line_high_ref, pool.close_time)
                line.set_y2(pool.line_high_ref, pool.high_val)
                line.set_color(pool.line_high_ref, pool.pool_color)

            // Create low price line if it doesn't exist, otherwise update it
            if na(pool.line_low_ref)
                pool.line_low_ref := line.new(x1=pool.open_time, y1=pool.low_val, x2=pool.close_time, y2=pool.low_val, color=pool.pool_color, width=1, xloc=xloc.bar_time)
            else
                line.set_x1(pool.line_low_ref, pool.open_time)
                line.set_y1(pool.line_low_ref, pool.low_val)
                line.set_x2(pool.line_low_ref, pool.close_time)
                line.set_y2(pool.line_low_ref, pool.low_val)
                line.set_color(pool.line_low_ref, pool.pool_color)

            // Main Info Label
            // Create main info label if it doesn't exist, otherwise update it
            if na(pool.label_info_ref)
                pool.label_info_ref := label.new(x=pool.open_time, y=pool.high_val, text=label_text_val, 
                                                  color=pool.pool_color, textcolor=color.white, 
                                                  style=label.style_label_down, size=size.large, xloc=xloc.bar_time)
            else
                label.set_xy(pool.label_info_ref, pool.open_time, pool.high_val)
                label.set_text(pool.label_info_ref, label_text_val)
                label.set_color(pool.label_info_ref, pool.pool_color)
                label.set_style(pool.label_info_ref, label.style_label_down) 
                label.set_size(pool.label_info_ref, size.large)

            // Initial Price Marker Label (currently active as per this version)
            if pool.initial_price > 0 // Only create/update if initial_price is valid
                if na(pool.label_initial_price_ref)
                    pool.label_initial_price_ref := label.new(x=pool.open_time, y=pool.initial_price, text="▲", 
                                                              color=pool.pool_color, textcolor=color.white, 
                                                              style=label.style_triangleup, size=size.small, 
                                                              xloc=xloc.bar_time)
                else
                    label.set_xy(pool.label_initial_price_ref, pool.open_time, pool.initial_price)
                    label.set_text(pool.label_initial_price_ref, "▲")
                    label.set_color(pool.label_initial_price_ref, pool.pool_color)
                    label.set_style(pool.label_initial_price_ref, label.style_triangleup)
                    label.set_size(pool.label_initial_price_ref, size.small)
            else // If initial_price is not valid (e.g., 0), delete the label if it exists
                if not na(pool.label_initial_price_ref)
                    label.delete(pool.label_initial_price_ref)
                    pool.label_initial_price_ref := na // Clear reference after deletion

    // If pool.show_pool is false, ensure existing drawing objects for this pool are removed from the chart
    else if barstate.islast 
        if not na(pool.line_high_ref)
            line.delete(pool.line_high_ref)
            pool.line_high_ref := na
        if not na(pool.line_low_ref)
            line.delete(pool.line_low_ref)
            pool.line_low_ref := na
        if not na(pool.label_info_ref)
            label.delete(pool.label_info_ref)
            pool.label_info_ref := na
        if not na(pool.label_initial_price_ref)
            label.delete(pool.label_initial_price_ref)
            pool.label_initial_price_ref := na