;; ============================================================================
;; CIRCULAR ECONOMY AGENT-BASED MODEL
;; ============================================================================
;; This model simulates a circular economy with two types of agents:
;; - Recyclers: environmentally conscious agents that prioritize sustainability
;; - Wastefuls: profit-driven agents that prioritize economic gain
;;
;; The model includes resource processing, trading, and environmental impacts.
;; Agent decision-making can be rule-based or AI-driven (using GPT-4o).
;;
;; Author: [Your Name]
;; Last Updated: [Date]
;; ============================================================================

;; ============================================================================
;; 1. EXTENSIONS AND BREED DECLARATIONS
;; ============================================================================

extensions [py csv]
breed [recyclers recycler]
breed [wastefuls wasteful]
directed-link-breed [waste-transfers waste-transfer]
directed-link-breed [resource-transfers resource-transfer]

;; ============================================================================
;; 2. VARIABLE DECLARATIONS
;; ============================================================================

globals [
  ;; Simulation control
  log-file-name
  api-key
  api-url
  api-requests-made
  api-request-limit
  last-api-call-time
  last-api-response
  last_prompt_sent
  last_gpt_response
  gpt-output-text

  ;; Economic tracking
  total-transactions
  average-transaction-price
  market-price-waste
  market-price-resource

  ;; Environmental metrics
  global-pollution-level
  total-new-resources
  total-recycled-resources
  total-waste
  recycling-efficiency
  waste-reduction-rate

  ;; Network metrics
  network-density
  average-node-degree
  centrality-index
  simulation-mode
]

turtles-own [
  selected?  ;; Whether this agent is selected for detailed view
  ;; Basic properties
  energy
  wealth
  operational-capacity
  operational-cost
  production-rate

  ;; Decision variables
  decision-history
  recent-rewards
  trading-partner
  has-traded?

  ;; Agent characteristics
  environmental-concern     ;; 0-1 scale of environmental priority
  economic-priority         ;; 0-1 scale of profit priority
  innovation-level          ;; 0-1 scale of willingness to adopt new tech
  cooperation-tendency      ;; 0-1 scale of willingness to cooperate

  ;; Production variables
  input-requirements        ;; Resources needed for production
  output-products           ;; Products/waste generated
  byproduct-utilization     ;; Efficiency of using byproducts
  residue-generated-type    ;; Type of waste produced
  residue-used-type         ;; Type of waste utilized
  capacity-utilization      ;; % of capacity being used

  ;; Network variables
  partners-list             ;; List of regular trading partners
  transaction-history       ;; Record of past transactions
  reputation                ;; Reputation score based on past behavior
  network-position          ;; Centrality in the network
]

patches-own [
  resource-type             ;; "new", "recycled", "waste"
  resource-quality          ;; 0-1 scale or "high"/"low" for waste
  last-changed              ;; Tick when resource last changed state
  region-type               ;; "industrial", "natural", or "waste-zone"
  cost-to-extract           ;; Base cost to extract resources
  pollution-level           ;; Environmental degradation (0-100)
  pollution-level-previous-tick
  carrying-capacity         ;; Max sustainable resource extraction
  regeneration-rate         ;; Speed of natural resource renewal
  pollution-sensitivity     ;; How sensitive area is to pollution
]

waste-transfers-own [
  waste-type                ;; Type of waste being transferred
  waste-quality             ;; Quality of waste (0-1)
  transfer-amount           ;; Quantity transferred
  transfer-price            ;; Price paid for transfer
  transfer-date             ;; Tick when transfer occurred
  transfer-efficiency       ;; Efficiency of the transfer (0-1)
]

resource-transfers-own [
  t-resource-type           ;; Type of resource being transferred
  t-resource-quality        ;; Quality of resource (0-1)
  t-transfer-amount         ;; Quantity transferred
  t-transfer-price          ;; Price paid for transfer
  t-transfer-date           ;; Tick when transfer occurred
  t-transfer-efficiency     ;; Efficiency of the transfer (0-1)
]

;; ============================================================================
;; 3. SETUP PROCEDURES
;; ============================================================================

;; Main setup procedure to initialize the simulation
to setup
  clear-all
  set-default-shape turtles "person"
  setup-python
  setup-globals
  setup-agents
  setup-patches
  setup-markets
  setup-log-files
  reset-ticks
end

;; Initialize global variables
to setup-globals
  set api-requests-made 0
  set api-request-limit 1000
  set market-price-waste 2
  set market-price-resource 5
  set global-pollution-level 0
  set total-transactions 0
  set total-new-resources 0
  set total-recycled-resources 0
  set total-waste 0
  set recycling-efficiency 0.7
  set waste-reduction-rate 0.1
end

;; Create and initialize agents
to setup-agents
  ;; Create recycler agents (environmentally focused)
  create-recyclers num-recyclers [
    set selected? false
    set color blue
    set size 1.5
    setxy random-pxcor random-pycor
    set energy max-stored-energy / 2
    set wealth 100
    set decision-history []
    set recent-rewards []
    set trading-partner nobody
    set has-traded? false

    ;; Set agent characteristics - recyclers are more environmentally concerned
    set environmental-concern 0.6 + random-float 0.4
    set economic-priority 0.3 + random-float 0.4
    set innovation-level 0.4 + random-float 0.6
    set cooperation-tendency 0.5 + random-float 0.5

    ;; Set production variables
    set operational-capacity 10 + random 10
    set operational-cost 2 + random 3
    set production-rate 0.8 + random-float 0.2
    set byproduct-utilization 0.7 + random-float 0.3
    set capacity-utilization 0.5 + random-float 0.5
    set residue-generated-type "low-toxicity"
    set residue-used-type "mixed"

    ;; Network variables
    set partners-list []
    set transaction-history []
    set reputation random-float 1.0
    set network-position 0
  ]

  ;; Create wasteful agents (profit focused)
  create-wastefuls num-wastefuls [
    set selected? false
    set color red
    set size 1.5
    setxy random-pxcor random-pycor
    set energy max-stored-energy / 2
    set wealth 100
    set decision-history []
    set recent-rewards []
    set trading-partner nobody
    set has-traded? false

    ;; Set agent characteristics - wastefuls are more economically concerned
    set environmental-concern 0.1 + random-float 0.3
    set economic-priority 0.7 + random-float 0.3
    set innovation-level 0.2 + random-float 0.5
    set cooperation-tendency 0.2 + random-float 0.4

    ;; Set production variables
    set operational-capacity 15 + random 10
    set operational-cost 1 + random 2
    set production-rate 0.9 + random-float 0.1
    set byproduct-utilization 0.2 + random-float 0.3
    set capacity-utilization 0.7 + random-float 0.3
    set residue-generated-type "high-toxicity"
    set residue-used-type "none"

    ;; Network variables
    set partners-list []
    set transaction-history []
    set reputation random-float 0.6
    set network-position 0
  ]
end

;; Initialize patches with resources
;; Initialize patches with resources and random quality
to setup-patches
  ask patches [
    set resource-type "new"
    set resource-quality random-float 1.0  ;; Random quality between 0 and 1
    set last-changed 0

    ;; Optional: distribute different resource types randomly
    if random 100 < 15 [  ;; 15% chance of starting as recycled
      set resource-type "recycled"
    ]
    if random 100 < 5 [   ;; 5% chance of starting as waste
      set resource-type "waste"
      ifelse random 100 < 50 [
        set resource-quality "high"
      ][
        set resource-quality "low"
      ]
    ]

    ;; Initialize other patch variables
    set region-type one-of ["industrial" "natural" "waste-zone"]
    set cost-to-extract 1 + random-float 4
    set pollution-level random 20  ;; Start with some random pollution
    set pollution-sensitivity 0.5 + random-float 0.5
    set carrying-capacity 50 + random 50
    set regeneration-rate 0.5 + random-float 1.5

    update-patch
  ]
end

;; Initialize market conditions
to setup-markets
  ;; Initialize market variables based on initial supply and demand
  set market-price-waste 2 + random-float 1
  set market-price-resource 5 + random-float 2
  set average-transaction-price (market-price-waste + market-price-resource) / 2
end

;; Setup Python environment and OpenAI integration
to setup-python
  py:setup py:python
  py:run "import openai"
  py:run "import os"
  py:run "import time"
  py:run "import random"
  py:run "import json"
  py:run "import math"
  py:run "import sys"
  py:run "openai.api_key = \"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\""
  py:run "elements_list = []"

  ; Setup OpenAI client - users will need to set their API key using set-api-key
  (py:run
    "def setup_openai_client(api_key):"
    "    if not api_key or api_key.strip() == '':"
    "        return False"
    "    try:"
    "        openai.api_key = api_key"
    "        # Test the connection with a simple query"
    "        response = openai.chat.completions.create("
    "            model='gpt-4o',"
    "            messages=[{'role': 'user', 'content': 'Say hello'}],"
    "            max_tokens=5"
    "        )"
    "        return True"
    "    except Exception as e:"
    "        print(f'Error setting up OpenAI client: {e}')"
    "        return False"
    ""
    "def get_agent_decision(agent_type, resource_type, energy, max_energy, history=None, rewards=None):"
    "    prompt = f'''"
    "Agent Simulation Status:"
    "- Agent type: {agent_type}"
    "- Resource at current location: {resource_type}"
    "- Current energy: {energy}"
    "- Maximum energy: {max_energy}"
    "- Recent decisions: {history[-5:] if history else 'No prior decisions'}"
    "- Recent rewards: {rewards[-5:] if rewards else 'No reward data'}"
    "- Local pollution level: {pollution_level}"
    "- Region type: {region_type}"
    "- Wealth: {wealth}"
    "- Nearby new resources: {nearby_new}"
    "- Nearby recycled resources: {nearby_recycled}"
    "- Nearby waste resources: {nearby_waste}"
    "Instruction:"
    "Based on the above status, decide the best next action for the agent. Options:"
    "1. process_resource"
    "2. seek_trade"
    "3. innovate"
    "4. expand_production"
    "5. move_only"
    ""
    "Reply with the action keyword."
    "'''"
    "    response = openai.chat.completions.create("
    "      model='gpt-4o',"
    "      messages=[{'role': 'user', 'content': prompt}],"
    "      max_tokens=300"
    "  )"
    "    global last_prompt_sent, last_gpt_response"
    "    last_prompt_sent = prompt"
    "    last_gpt_response = response.choices[0].message.content"
    "    return last_gpt_response"
    "    '''Get decision from GPT-4o for agent behavior'''"
    "    if history is None:"
    "        history = []"
    "    if rewards is None:"
    "        rewards = []"
    ""
    "    # Create a prompt based on agent type and environment"
    "    if agent_type == 'recycler':"
    "        prompt = f'''You are simulating the behavior of an environmentally conscious recycler agent in a resource management simulation."
    "Your current status:"
    "- Current energy level: {energy} (Max: {max_energy})"
    "- You are on a {resource_type} resource cell"
    "- Decision history: {history[-5:] if len(history) > 0 else 'No prior decisions'}"
    "- Recent rewards: {rewards[-5:] if len(rewards) > 0 else 'No reward data'}"
    ""
    "As a recycler, you generally:"
    "- Prefer sustainable resource use"
    "- Willing to recycle waste even at personal cost"
    "- Think long-term about resource availability"
    ""
    "Based on these factors, what action will you take?"
    "Options:"
    "1. process_resource (use the resource in your current cell)"
    "2. move_only (just move without using the resource)"
    ""
    "Reply with ONLY the option number (1 or 2).'''"
    ""
    "    else:  # wasteful agent"
    "        prompt = f'''You are simulating the behavior of a wasteful developer agent in a resource management simulation."
    "Your current status:"
    "- Current energy level: {energy} (Max: {max_energy})"
    "- You are on a {resource_type} resource cell"
    "- Decision history: {history[-5:] if len(history) > 0 else 'No prior decisions'}"
    "- Recent rewards: {rewards[-5:] if len(rewards) > 0 else 'No reward data'}"
    ""
    "As a wasteful agent, you generally:"
    "- Prioritize maximum immediate resource extraction"
    "- Care less about long-term sustainability"
    "- Avoid waste cells as they provide no benefit"
    "- Don't care about recycling"
    ""
    "Based on these factors, what action will you take?"
    "Options:"
    "1. process_resource (use the resource in your current cell)"
    "2. move_only (just move without using the resource)"
    ""
    "Reply with ONLY the option number (1 or 2).'''"
    ""
    "    try:"
    "        response = openai.chat.completions.create("
    "            model='gpt-4o',"
    "            messages=[{'role': 'user', 'content': prompt}],"
    "            max_tokens=10,"
    "            temperature=0.7"
    "        )"
    "        decision = response.choices[0].message.content.strip()"
    ""
    "        # Extract just the number from response"
    "        if '1' in decision:"
    "            return 'process_resource'"
    "        elif '2' in decision:"
    "            return 'move_only'"
    "        elif '3' in decision:"
    "            return 'seek_trade'"
    "        elif '4' in decision:"
    "            if agent_type == 'recycler':"
    "                return 'innovate'"
    "            else:"
    "                return 'expand_production'"
    "        else:"
    "            # Default to move if response is unclear"
    "            return 'move_only'"
    "    except Exception as e:"
    "        print(f'Error getting decision from GPT-4o: {e}')"
    "        # Return random decision on error"
    "        return random.choice(['process_resource', 'move_only', 'seek_trade', 'innovate' if agent_type == 'recycler' else 'expand_production'])"
    ""
    "def get_autonomous_decision(agent_type, environment_state):"
    "    '''Get a more flexible decision based on complete environment state'''"
    "    state_str = json.dumps(environment_state)"
    ""
    "    prompt = f'''You are an autonomous agent in a resource management simulation."
    ""
    "Agent type: {agent_type}"
    "Environment state: {state_str}"
    ""
    "As a {agent_type} agent, make a decision about what action to take next."
    "Your decision should include:"
    "1. The primary action to take (process_resource or move_only)"
    "2. A brief explanation for your decision"
    "3. Any suggestions for long-term strategy"
    ""
    "Format your response as a JSON object with keys: 'action', 'reasoning', 'strategy'"
    "'''"
    ""
    "    try:"
    "        response = openai.chat.completions.create("
    "            model='gpt-4o',"
    "            messages=[{'role': 'user', 'content': prompt}],"
    "            max_tokens=200,"
    "            temperature=0.7"
    "        )"
    "        result = response.choices[0].message.content.strip()"
    ""
    "        # Try to parse as JSON"
    "        try:"
    "            decision_object = json.loads(result)"
    "            return decision_object"
    "        except:"
    "            # If parsing fails, extract just the action"
    "            if 'process_resource' in result.lower():"
    "                return {'action': 'process_resource', 'reasoning': 'Default', 'strategy': 'Default'}"
    "            elif 'seek_trade' in result.lower():"
    "                return {'action': 'seek_trade', 'reasoning': 'Default', 'strategy': 'Default'}"
    "            elif 'innovate' in result.lower() or 'expand_production' in result.lower():"
    "                return {'action': 'innovate' if agent_type == 'recycler' else 'expand_production', 'reasoning': 'Default', 'strategy': 'Default'}"
    "            else:"
    "                return {'action': 'move_only', 'reasoning': 'Default', 'strategy': 'Default'}"
    "    except Exception as e:"
    "        print(f'Error getting autonomous decision: {e}')"
    "        return {'action': random.choice(['process_resource', 'move_only', 'seek_trade', 'innovate' if agent_type == 'recycler' else 'expand_production']), 'reasoning': 'Error fallback', 'strategy': 'Random'}"
    ""
    "def store_latest_prompt_response(agent_id, prompt, response):"
    "    global elements_list"
    "    # Store agent prompts and responses in a way they can be retrieved"
    "    # First check if we already have an entry for this agent"
    "    found = False"
    "    for i, entry in enumerate(elements_list):"
    "        if entry.get('agent_id') == agent_id:"
    "            elements_list[i] = {'agent_id': agent_id, 'prompt': prompt, 'response': response}"
    "            found = True"
    "            break"
    "    if not found:"
    "        elements_list.append({'agent_id': agent_id, 'prompt': prompt, 'response': response})"
    ""
    "def get_latest_prompt_response(agent_id):"
    "    global elements_list"
    "    for entry in elements_list:"
    "        if entry.get('agent_id') == agent_id:"
    "            return entry.get('prompt', ''), entry.get('response', '')"
    "    return '', ''"
    ""
    "# Enhanced agent decision function with better context and balanced decision incentives"
    "def get_agent_decision(agent_id, agent_type, resource_type, energy, max_energy, history=None, rewards=None, pollution_level=0, region_type='', wealth=0, nearby_new=0, nearby_recycled=0, nearby_waste=0, market_price_waste=0, market_price_resource=0, global_pollution_level=0, total_transactions=0, recycling_efficiency=0, network_density=0, ticks=0, recycling_waste_cost=2):"
    "    if history is None:"
    "        history = []"
    "    if rewards is None:"
    "        rewards = []"
    "    "
    "    # Calculate energy percentage for clearer status"
    "    energy_percentage = round((energy / max_energy) * 100)"
    "    "
    "    # Determine current economic and environmental status"
    "    economic_status = \"stable\""
    "    if wealth < 50:"
    "        economic_status = \"struggling\""
    "    elif wealth > 150:"
    "        economic_status = \"thriving\""
    "        "
    "    environmental_status = \"moderate\""
    "    if pollution_level > 50:"
    "        environmental_status = \"degraded\""
    "    elif pollution_level < 20:"
    "        environmental_status = \"healthy\""
    "    "
    "    # Create decision impact descriptions based on agent type"
    "    if agent_type == \"recyclers\":"
    "        decision_impacts = {"
    "            \"process_resource\": {"
    "                \"new\": \"Gain moderate energy (+2), maintain resource sustainability\","
    "                \"recycled\": \"Gain small energy (+1), maintain resource in recycled state\","
    "                \"waste\": f\"Cost energy ({recycling_waste_cost}), convert waste to recycled resource, environmental benefit\""
    "            },"
    "            \"seek_trade\": \"Potential to gain wealth through trading, increases economic activity and network connections\","
    "            \"innovate\": \"Cost of 5 energy, improves long-term efficiency and reputation, reduces operational costs\","
    "            \"expand_production\": \"Not recommended for recyclers - better to innovate instead\","
    "            \"move_only\": \"Cost of 1 energy, useful when current location offers no benefits or to reach better resources\""
    "        }"
    "    else:  # wastefuls"
    "        decision_impacts = {"
    "            \"process_resource\": {"
    "                \"new\": \"Gain high energy (+4), but converts resource to waste\","
    "                \"recycled\": \"Gain moderate energy (+2), converts resource to waste\","
    "                \"waste\": \"No energy gain, not beneficial\""
    "            },"
    "            \"seek_trade\": \"Potential to sell waste for profit, increases economic activity\","
    "            \"innovate\": \"Not recommended for wastefuls - better to expand production instead\","
    "            \"expand_production\": \"Cost of 3 energy, increases capacity and production rate, but increases pollution\","
    "            \"move_only\": \"Cost of 1 energy, useful to find new resources to exploit\""
    "        }"
    "    "
    "    # Previous decision patterns to encourage diversity"
    "    decision_counts = {}"
    "    for d in history:"
    "        if d in decision_counts:"
    "            decision_counts[d] += 1"
    "        else:"
    "            decision_counts[d] = 1"
    "    "
    "    most_used_decision = max(decision_counts.items(), key=lambda x: x[1])[0] if decision_counts else \"none\""
    "    "
    "    # Create the enhanced prompt with more context and strategic information"
    "    prompt = f\"\"\""
    "Agent Simulation Status:"
    "- Agent ID: {agent_id}"
    "- Agent type: {agent_type}"
    "- Resource at current location: {resource_type}"
    "- Current energy: {energy}/{max_energy} ({energy_percentage}%)"
    "- Economic status: {economic_status} (Wealth: {wealth})"
    "- Environmental context: {environmental_status} (Pollution: {pollution_level}/100)"
    "- Simulation time: Tick {ticks}"
    ""
    "Resource Context:"
    "- At current location: {resource_type}"
    "- Nearby resources: New ({nearby_new}), Recycled ({nearby_recycled}), Waste ({nearby_waste})"
    "- Region type: {region_type}"
    ""
    "Market & Global Context:"
    "- Market price for resources: {market_price_resource}"
    "- Market price for waste: {market_price_waste}"
    "- Global pollution level: {global_pollution_level}/100"
    "- Total economic transactions: {total_transactions}"
    "- Recycling efficiency: {recycling_efficiency}"
    "- Network connectivity: {network_density}"
    ""
    "Decision History:"
    "- Recent decisions: {history[-5:] if history else 'No prior decisions'}"
    "- Most frequent decision: {most_used_decision}"
    "- Recent rewards: {rewards[-5:] if rewards else 'No reward data'}"
    ""
    "AVAILABLE ACTIONS AND THEIR IMPACTS:"
    ""
    "1. process_resource - {decision_impacts[\"process_resource\"].get(resource_type, \"Not applicable for current resource\")}"
    ""
    "2. seek_trade - {decision_impacts[\"seek_trade\"]}"
    "   Note: Trading is essential for economic system health. The simulation currently shows 90% fewer transactions with GPT agents."
    ""
    "3. innovate - {decision_impacts[\"innovate\"]}"
    "   Note: This is a key action for recyclers to improve long-term sustainability."
    ""
    "4. expand_production - {decision_impacts[\"expand_production\"]}"
    "   Note: This is an important action for wastefuls to increase economic output."
    ""
    "5. move_only - {decision_impacts[\"move_only\"]}"
    ""
    "Strategic Considerations:"
    "- Environmental sustainability requires balancing resource use with regeneration"
    "- Economic sustainability requires regular trading and production"
    "- Decision diversity leads to better overall system performance"
    "- Your decision affects both your individual performance and the entire system"
    "- If you always make the same decision, the system becomes imbalanced"
    ""
    "Based on all these factors, what is your next action?"
    "Reply with ONLY ONE of: process_resource, seek_trade, innovate, expand_production, or move_only."
    "\"\"\""
    ""
    "    try:"
    "        response = openai.chat.completions.create("
    "            model='gpt-4o',"
    "            messages=[{'role': 'user', 'content': prompt}],"
    "            max_tokens=50,"
    "            temperature=0.8  # Slightly increased temperature to encourage decision diversity"
    "        )"
    "        result = response.choices[0].message.content.strip().lower()"
    "        "
    "        # Clean up and validate the response"
    "        valid_decisions = [\"process_resource\", \"seek_trade\", \"innovate\", \"expand_production\", \"move_only\"]"
    "        result = next((d for d in valid_decisions if d in result), \"move_only\")"
    "        "
    "        # Store the prompt and response for analysis"
    "        store_latest_prompt_response(agent_id, prompt, result)"
    "        return result"
    "    except Exception as e:"
    "        print(f'Error getting decision from GPT: {e}')"
    "        # More strategic fallback: prefer different action from most common"
    "        if most_used_decision == \"process_resource\":"
    "            return random.choice([\"seek_trade\", \"move_only\", \"innovate\" if agent_type == \"recyclers\" else \"expand_production\"])"
    "        return random.choice(['process_resource', 'move_only', 'seek_trade', 'innovate' if agent_type == \"recyclers\" else \"expand_production\"])"
    )
end

;; Setup logging files for data collection
to setup-log-files
  if enable-logging? [
    ;; Setup agent data log
    file-open "agent_data.csv"
    file-print "simulation_mode,ticks,who,breed,energy,wealth,operational_capacity,operational_cost,production_rate,environmental_concern,economic_priority,innovation_level,cooperation_tendency,byproduct_utilization,capacity_utilization,region_type,resource_type,resource_quality,pollution_level,residue_generated_type,residue_used_type,reputation,network_position"
    file-close

    ;; Setup patch data log
    file-open "patch_data.csv"
    file-print "simulation_mode,ticks,pxcor,pycor,resource_type,resource_quality,pollution_level,region_type,cost_to_extract,carrying_capacity,regeneration_rate,pollution_sensitivity,last_changed,agent_present,agent_type"
    file-close

    ;; Setup global data log
    file-open "global_data.csv"
    file-print "simulation_mode,ticks,total_new_resources,total_recycled_resources,total_waste,global_pollution_level,market_price_waste,market_price_resource,total_transactions,average_transaction_price,recycling_efficiency,waste_reduction_rate,network_density,average_node_degree,centrality_index,api_requests_made,total_agent_count,recycler_count,wasteful_count"
    file-close

    ;; Setup transaction data log
    file-open "transaction_data.csv"
    file-print "simulation_mode,ticks,sender_id,sender_type,receiver_id,receiver_type,transfer_type,transfer_amount,transfer_price,resource_type,resource_quality,transfer_efficiency,transfer_date"
    file-close

    ;; Setup GPT conversation log
    file-open "gpt_data.csv"
    file-print "simulation_mode,ticks,who,breed,energy,wealth,decision_made,prompt_sent,gpt_response"
    file-close
  ]
end

;; ============================================================================
;; 4. RUNTIME PROCEDURES
;; ============================================================================

;; Main simulation step procedure
to go
  select-agent
  ;; Stop conditions
  if not any? turtles [ stop ]  ; Stop if all agents die
  if use-gpt? and (api-requests-made >= api-request-limit) [ stop ]  ; Stop if API limit reached
  if ticks >= 50 [ stop ]  ; Stop if ticks reach 50

  ;; Update market conditions
  update-market-conditions

  ;; Agent decision-making and actions
  ask turtles [
    ifelse use-gpt? [
      ;; GPT-based decision making
      gpt-make-decision (word breed)
    ] [
      ;; Rule-based decision making
      rule-based-make-decision (word breed)
    ]
  ]

  ;; Process trading
  ask turtles [
    if energy > 0 [  ;; Only active agents can trade
      execute-initiated-trades
      reset-trading-status
    ]
  ]

  ;; Update agent statuses
  ask turtles [
    update-agent-status
    if energy <= 0 [ die ]
  ]

  ;; Environmental updates
  update-environment
  calculate-environmental-impact
  update-network-metrics

  ;; Visualization updates
  update-visualization

  ;; Data logging
  if enable-logging? [
    log-simulation-data
  ]

  tick
end

;; ============================================================================
;; 5. AGENT DECISION-MAKING PROCEDURES
;; ============================================================================

;; Process resources based on agent type
to process-resources [agent-type]
  ifelse agent-type = "recycler" [
    recycler-process-patch
  ] [
    wasteful-process-patch
  ]
end

;; GPT-based decision making for agents
to gpt-make-decision [agent-type]
  ;; Record API request
  set api-requests-made api-requests-made + 1

  ifelse use-simple-prompts? [
    ;; Simple prompt-based decision (old approach)
    let decision py:runresult (word "get_agent_decision('" agent-type "', '" [resource-type] of patch-here "', " energy ", " max-stored-energy ", " decision-history ", " recent-rewards ")")

    let latest-prompt py:runresult "last_prompt_sent"
    let latest-response py:runresult "last_gpt_response"

    if length decision-history > 10 [
      set decision-history but-first decision-history
    ]

    ;; Execute the decision
    let old-energy energy

    (ifelse
      decision = "process_resource" [
        process-resources agent-type
      ]
      decision = "seek_trade" [
        initiate-trade
      ]
      decision = "innovate" [
        innovate-processes
      ]
      decision = "expand_production" [
        expand-production
      ]
      ;; Default is move
      [move]
    )

    ;; Record the reward
    set recent-rewards lput (energy - old-energy) recent-rewards
    if length recent-rewards > 10 [
      set recent-rewards but-first recent-rewards
    ]
  ] [
    ;; Enhanced context-based decision making (new approach)
    ;; Gather additional information for better context
    let nearby-new-count count neighbors with [resource-type = "new"]
    let nearby-recycled-count count neighbors with [resource-type = "recycled"]
    let nearby-waste-count count neighbors with [resource-type = "waste"]

    ;; Set Python variables for enhanced decision making
    py:set "agent_id" who
    py:set "agent_type" agent-type
    py:set "resource_type" [resource-type] of patch-here
    py:set "energy" energy
    py:set "max_energy" max-stored-energy
    py:set "history" decision-history
    py:set "rewards" recent-rewards
    py:set "pollution_level" [pollution-level] of patch-here
    py:set "region_type" [region-type] of patch-here
    py:set "wealth" wealth
    py:set "nearby_new" nearby-new-count
    py:set "nearby_recycled" nearby-recycled-count
    py:set "nearby_waste" nearby-waste-count
    py:set "market_price_waste" market-price-waste
    py:set "market_price_resource" market-price-resource
    py:set "global_pollution_level" global-pollution-level
    py:set "total_transactions" total-transactions
    py:set "recycling_efficiency" recycling-efficiency
    py:set "network_density" network-density
    py:set "ticks" ticks
    py:set "recycling_waste_cost" recycling-waste-cost

    ;; Get enhanced decision with full context
    let decision py:runresult (word
      "get_agent_decision(agent_id, agent_type, resource_type, energy, max_energy, "
      "history, rewards, pollution_level, region_type, wealth, nearby_new, "
      "nearby_recycled, nearby_waste, market_price_waste, market_price_resource, "
      "global_pollution_level, total_transactions, recycling_efficiency, network_density, ticks)")

    ;; Record the decision in history
    set decision-history lput decision decision-history
    if length decision-history > 10 [
      set decision-history but-first decision-history
    ]

    ;; Execute the decision
    let old-energy energy

    (ifelse
      decision = "process_resource" [
        process-resources agent-type
      ]
      decision = "seek_trade" [
        initiate-trade
      ]
      decision = "innovate" [
        innovate-processes
      ]
      decision = "expand_production" [
        expand-production
      ]
      ;; Default is move
      [move]
    )

    ;; Record the reward
    set recent-rewards lput (energy - old-energy) recent-rewards
    if length recent-rewards > 10 [
      set recent-rewards but-first recent-rewards
    ]
  ]
end

;; Rule-based decision making for agents
to rule-based-make-decision [agent-type]
  ;; This procedure implements rule-based decision making without GPT
  let decision-value ""

  ;; Record the current energy
  let old-energy energy

  ;; Base decisions on agent type and environment
  ifelse agent-type = "recycler" [
    ;; Recycler decision making
    (ifelse
      ;; If on waste patch with enough energy, recycle it
      [resource-type] of patch-here = "waste" and energy > recycling-waste-cost [
        set decision-value "process_resource"
        process-resources agent-type
      ]
      ;; If on recycled patch, process it
      [resource-type] of patch-here = "recycled" [
        set decision-value "process_resource"
        process-resources agent-type
      ]
      ;; If on new resources patch, process it
      [resource-type] of patch-here = "new" [
        set decision-value "process_resource"
        process-resources agent-type
      ]
      ;; Look for trading opportunities when energy is medium
      energy > (max-stored-energy * 0.4) and energy < (max-stored-energy * 0.7) and
      random-float 1.0 < cooperation-tendency [
        set decision-value "seek_trade"
        initiate-trade
      ]
      ;; Innovate when energy is high
      energy > (max-stored-energy * 0.8) and random-float 1.0 < innovation-level [
        set decision-value "innovate"
        innovate-processes
      ]
      ;; Otherwise move
      [
        set decision-value "move"
        move
      ]
    )
  ] [
    ;; Wasteful decision making
    (ifelse
      ;; If on new resources patch, extract aggressively
      [resource-type] of patch-here = "new" [
        set decision-value "process_resource"
        process-resources agent-type
      ]
      ;; If on recycled patch and profitable, process it
      [resource-type] of patch-here = "recycled" and energy < (max-stored-energy * 0.7) [
        set decision-value "process_resource"
        process-resources agent-type
      ]
      ;; Look for trading opportunities when waste is valuable
      ([resource-type] of patch-here = "waste" and
       [resource-quality] of patch-here = "high" and
       energy < (max-stored-energy * 0.6)) [
        set decision-value "seek_trade"
        initiate-trade
      ]
      ;; Expand production when energy is high
      energy > (max-stored-energy * 0.7) and random-float 1.0 < economic-priority [
        set decision-value "expand_production"
        expand-production
      ]
      ;; Otherwise move
      [
        set decision-value "move"
        move
      ]
    )
  ]

  ;; Record the decision and reward
  set decision-history lput decision-value decision-history
  if length decision-history > 10 [
    set decision-history but-first decision-history
  ]

  set recent-rewards lput (energy - old-energy) recent-rewards
  if length recent-rewards > 10 [
    set recent-rewards but-first recent-rewards
  ]
end

;; Agent movement procedure
to move  ;; turtle procedure
  let target-patch one-of neighbors

  if (agents-seek-resources?) [
    let candidate-moves neighbors with [ resource-type = "new" ]
    ifelse any? candidate-moves [
      set target-patch one-of candidate-moves
    ] [
      set candidate-moves neighbors with [ resource-type = "recycled" ]
      if any? candidate-moves [
        set target-patch one-of candidate-moves
      ]
    ]
  ]

  face target-patch
  move-to target-patch
  set energy (energy - 1)
end

;; Initiate trading with nearby agents
to initiate-trade
  ;; Find potential trading partners nearby
  let potential-partners other turtles in-radius 3 with [not has-traded?]

  if any? potential-partners [
    let partner one-of potential-partners

    ;; Set up the trading relationship
    set trading-partner partner
    set has-traded? true
    ask partner [
      set trading-partner myself
      set has-traded? true
    ]
  ]
end

;; Expand production capacity (for wasteful agents)
to expand-production
  ;; For wastefuls: expand production at environmental cost
  if breed = wastefuls [
    let expansion-cost 3

    if energy > expansion-cost [
      set energy energy - expansion-cost
      set operational-capacity operational-capacity * 1.05
      set production-rate min list 1.0 (production-rate + 0.02)

      ;; Environmental impact of expansion
      ask patch-here [
        set pollution-level pollution-level + 5
      ]
    ]
  ]
end

;; Improve process efficiency (for recycler agents)
to innovate-processes
  ;; For recyclers: invest in improving processing efficiency
  if breed = recyclers [
    let innovation-cost 5

    if energy > innovation-cost [
      set energy energy - innovation-cost
      set innovation-level min list 1.0 (innovation-level + 0.05)
      set byproduct-utilization min list 1.0 (byproduct-utilization + 0.05)
      set operational-cost max list 1.0 (operational-cost * 0.95)
      set reputation reputation + 0.02
    ]
  ]
end

;; ============================================================================
;; 6. RESOURCE PROCESSING PROCEDURES
;; ============================================================================

;; Recycler agent resource processing
to recycler-process-patch
  ifelse (resource-type = "new") [
    if (energy <= max-stored-energy - 2) [
      set energy energy + 2
    ]
  ] [
    ifelse (resource-type = "recycled") [
      if (energy <= max-stored-energy - 1) [
        set energy energy + 1
      ]
    ] [
      set energy energy - recycling-waste-cost
      set resource-type "recycled"
      ask patch-here [
        set last-changed ticks
      ]
    ]
  ]
end

;; Wasteful agent resource processing
to wasteful-process-patch
  ifelse (resource-type = "new") [
    if (energy <= max-stored-energy - 4) [
      set energy energy + 4
      set resource-type "waste"
      ifelse random 100 < 50 [
        set resource-quality "high" ; there is a 50% chance it's high quality
      ][
        set resource-quality "low"
      ]

      ask patch-here [
        set last-changed ticks
      ]
    ]
  ] [
    if (resource-type = "recycled") [
      if (energy <= max-stored-energy - 2) [
        set energy energy + 2
        set resource-type "waste"
        ask patch-here [
          set last-changed ticks
        ]
      ]
    ]
  ]
  ; if resource-type is "waste", then we gain nothing.
end

;; ============================================================================
;; 7. TRADING PROCEDURES
;; ============================================================================

;; Attempt to trade with nearby agents
to attempt-trade
  ; Only wastefuls with waste can offer
  if breed = wastefuls and [resource-type] of patch-here = "waste" and not has-traded? [
    let nearby-turtles turtles-on neighbors
    let nearby-recyclers nearby-turtles with [
      breed = recyclers and not has-traded? and [resource-quality] of patch-here = "high"
    ]

    if any? nearby-recyclers [
      let partner one-of nearby-recyclers
      ; Initiate trade
      set trading-partner partner
      set has-traded? true
      ask partner [
        set trading-partner myself
        set has-traded? true
      ]
      execute-trade
    ]
  ]
end

;; Execute a direct trade between two agents
to execute-trade
  ; Only valid if both partners exist
  if trading-partner != nobody [
    ; Simple trade rule:
    ; Recycler pays energy to wasteful to recycle the waste

    let trade-cost 3     ; Cost to recycler (energy spent to recycle waste)
    let reward-amount 2  ; Reward to wasteful (energy received for selling waste)

    ; Only proceed if recycler has enough energy
    if [energy] of trading-partner >= trade-cost [
      ask trading-partner [
        set energy energy - trade-cost
        set resource-type "recycled"
        set last-changed ticks
      ]
      ; Wasteful gets a reward
      set energy energy + reward-amount
    ]
  ]
end

;; Execute trades initiated by agents
to execute-initiated-trades
  ;; Only proceed if there's a trading partner assigned
  if trading-partner != nobody and [trading-partner] of trading-partner = self [
    let trade-happened? false

    ;; Determine trade types based on agent types
    ifelse breed = recyclers and [breed] of trading-partner = wastefuls [
      ;; Recycler buying waste from wasteful
      if [patch-here] of trading-partner != nobody and
         [[resource-type] of patch-here] of trading-partner = "waste" and
         [[resource-quality] of patch-here] of trading-partner = "high" [

        ;; Negotiated price based on market and agent characteristics
        let base-price market-price-waste
        let negotiation-factor (economic-priority + [cooperation-tendency] of trading-partner) / 2
        let final-price base-price * (0.8 + negotiation-factor * 0.4)

        ;; Execute the trade if both parties can afford it
        if wealth >= final-price and [energy] of trading-partner > 0 [
          ;; Transfer wealth
          set wealth wealth - final-price
          ask trading-partner [set wealth wealth + final-price]

          ;; Create link to visualize the transaction
          create-waste-transfer-to trading-partner [
            set color yellow
            set thickness 0.2
            set waste-type "high-quality"
            set waste-quality 0.8
            set transfer-amount 1
            set transfer-price final-price
            set transfer-date ticks
            set transfer-efficiency 0.9
          ]

          ;; Record the transaction
          set total-transactions total-transactions + 1
          set average-transaction-price (average-transaction-price * (total-transactions - 1) + final-price) / total-transactions

          ;; Add to partnership network
          if not member? trading-partner partners-list [
            set partners-list lput trading-partner partners-list
          ]

          ;; Environmental benefit from trading waste
          ask [patch-here] of trading-partner [
            set resource-type "recycled"
            set resource-quality 0.5
            set pollution-level max list 0 (pollution-level - 5)
          ]

          set trade-happened? true
        ]
      ]
    ][
      ;; Other trading relationships (resource trading)
      if [patch-here] of trading-partner != nobody and
         [[resource-type] of patch-here] of trading-partner = "new" [

        ;; Resource trading (sharing raw materials)
        let base-price market-price-resource
        let negotiation-factor (cooperation-tendency + [cooperation-tendency] of trading-partner) / 2
        let final-price base-price * (0.9 + negotiation-factor * 0.2)

        if wealth >= final-price / 2 and [energy] of trading-partner > 0 [
          ;; Split the cost
          let split-price final-price / 2
          set wealth wealth - split-price
          ask trading-partner [set wealth wealth - split-price]

          ;; Both gain energy from collaboration
          let energy-gain 3
          set energy energy + energy-gain
          ask trading-partner [set energy energy + energy-gain]

          ;; Create link to visualize collaboration
          create-resource-transfer-to trading-partner [
            set color green
            set thickness 0.2
            set t-resource-type "shared"
            set t-resource-quality 0.7
            set t-transfer-amount 1
            set t-transfer-price split-price
            set t-transfer-date ticks
            set t-transfer-efficiency 0.8
          ]

          ;; Record the transaction
          set total-transactions total-transactions + 1

          ;; Add to partnership network
          if not member? trading-partner partners-list [
            set partners-list lput trading-partner partners-list
          ]

          set trade-happened? true
        ]
      ]
    ]

    ;; Update reputation based on trade outcome
    if trade-happened? [
      set reputation reputation + 0.01
      ask trading-partner [set reputation reputation + 0.01]
    ]
  ]
end

;; Reset trading status after trade attempt
to reset-trading-status
  set trading-partner nobody
  set has-traded? false
end

;; ============================================================================
;; 8. ENVIRONMENT UPDATE PROCEDURES
;; ============================================================================

;; Calculate environmental impacts
to calculate-environmental-impact
  ;; Calculate global environmental metrics
  set global-pollution-level mean [pollution-level] of patches

  ;; Calculate recycling efficiency (how much waste is being recycled)
  let recycled-this-tick count patches with [
    resource-type = "recycled" and last-changed = ticks
  ]
  let waste-created-this-tick count patches with [
    resource-type = "waste" and last-changed = ticks
  ]

  if waste-created-this-tick > 0 [
    set recycling-efficiency (recycled-this-tick / (waste-created-this-tick + recycled-this-tick))
  ]

  ;; Calculate waste reduction rate
  let previous-waste-count count patches with [resource-type = "waste" and ticks > 0]
  let current-waste-count count patches with [resource-type = "waste"]

  if previous-waste-count > 0 and ticks > 10 [
    set waste-reduction-rate 1 - (current-waste-count / previous-waste-count)
  ]
end

;; Update market prices and economic conditions
to update-market-conditions
  ;; Calculate supply and demand
  let new-resource-count count patches with [resource-type = "new"]
  let waste-count count patches with [resource-type = "waste"]
  let recycled-count count patches with [resource-type = "recycled"]

  ;; Update market prices based on resource availability
  set market-price-resource max list 1 (5 + (200 / (new-resource-count + 1)) - (recycled-count / 20))
  set market-price-waste max list 0.5 (2 + (waste-count / 50) - (recycled-count / 30))

  ;; Apply market volatility
  set market-price-resource market-price-resource * (0.95 + random-float 0.1)
  set market-price-waste market-price-waste * (0.95 + random-float 0.1)

  ;; Track global resource statistics
  set total-new-resources new-resource-count
  set total-recycled-resources recycled-count
  set total-waste waste-count
end

;; Update environment conditions
to update-environment
  ask patches with [ resource-type = "recycled" ] [
    if random 100 < (resource-regeneration / 10) [
      set resource-type "new"
      set last-changed ticks
    ]
  ]

  ; waste is less likely to be renewed naturally by the environment
  ; in this model, we arbitrarily assume 5 times less likely
  ask patches with [ resource-type = "waste" ] [
    if (random 5 = 0) and (random 100 < (resource-regeneration / 10)) [
      set resource-type "new"
      set last-changed ticks
    ]
  ]
end

;; Update network metrics
to update-network-metrics
  ;; Calculate network metrics for industrial symbiosis
  let total-links count waste-transfers + count resource-transfers
  let max-possible-links (count turtles * (count turtles - 1))

  ;; Network density
  ifelse max-possible-links > 0 [
    set network-density total-links / max-possible-links
  ][
    set network-density 0
  ]

  ;; Average node degree
  ifelse count turtles > 0 [
    set average-node-degree mean [length partners-list] of turtles
  ][
    set average-node-degree 0
  ]

  ;; Calculate centrality (simplified)
  ask turtles [
    set network-position (count my-links) / (count turtles - 1)
  ]

  ;; Centrality index
  set centrality-index variance [network-position] of turtles
end

;; Update agent status
to update-agent-status
  ;; Cap energy at maximum
  if energy > max-stored-energy [
    set energy max-stored-energy
  ]

  ;; Environmental effects on agents
  let local-pollution [pollution-level] of patch-here
  if local-pollution > 50 [
    ;; High pollution reduces energy
    set energy energy - (local-pollution / 1000)
  ]

  ;; Production costs
  set energy energy - (operational-cost * capacity-utilization / 20)

  ;; Convert some wealth to energy if very low
  if energy < 5 and wealth > 10 [
    let conversion-amount min list 5 (wealth / 5)
    set energy energy + conversion-amount
    set wealth wealth - (conversion-amount * 2)
  ]
end

;; ============================================================================
;; 9. VISUALIZATION PROCEDURES
;; ============================================================================
;; Update visualization of agents and patches
to update-visualization
  ;; Update patch appearance
  ask patches [ update-patch ]

  ;; Update agent labels and appearance
  ask turtles [
    ifelse show-energy? [
      set label precision energy 1
    ][
      set label ""
    ]

    ;; Highlight selected agents
    ifelse selected? [
      set size 2.5  ;; Make selected agents larger
    ][
      set size 1.5  ;; Normal size for others
    ]
  ]

  ;; Update link appearance
  ask waste-transfers [
    ;; Links fade over time
    set thickness max list 0.1 (0.5 - ((ticks - transfer-date) * 0.01))
    if thickness <= 0.1 or ticks - transfer-date > 20 [ die ]
  ]

  ask resource-transfers [
    ;; Use t-transfer-date instead of transfer-date
    set thickness max list 0.1 (0.5 - ((ticks - t-transfer-date) * 0.01))
    if thickness <= 0.1 or ticks - t-transfer-date > 20 [ die ]
  ]
end

;; Update patch appearance based on resource type
to update-patch
  ifelse (resource-type = "new") [
    set pcolor green
  ] [
    ifelse (resource-type = "recycled") [
      set pcolor lime
    ] [
      ; Waste patch
      ifelse resource-quality = "high" [
        set pcolor yellow
      ][
        set pcolor yellow - 2
      ]
    ]
  ]
end

;; ============================================================================
;; 10. DATA LOGGING PROCEDURES
;; ============================================================================

;; Main logging procedure that calls individual log procedures
to log-simulation-data
  log-agent-data
  log-patch-data
  log-global-data
  log-transaction-data
  log-gpt-conversations
end

;; ============================================================================
;; Log agent data to CSV
;;
;; Records detailed information about each agent in the simulation:
;; - Agent identity (who, breed)
;; - Resource stats (energy, wealth)
;; - Operational parameters (capacity, cost, production rate)
;; - Agent characteristics (environmental concern, economic priority, etc.)
;; - Current environment (region type, resource type)
;; - Social metrics (reputation, network position)
;; ============================================================================
to log-agent-data
  if not enable-logging? [ stop ]

  file-open "agent_data.csv"
  ask turtles [
    file-type (word simulation-mode "," ticks "," who "," breed "," precision energy 2 ","
      precision wealth 2 "," precision operational-capacity 2 "," precision operational-cost 2 ","
      precision production-rate 2 "," precision environmental-concern 2 "," precision economic-priority 2 ","
      precision innovation-level 2 "," precision cooperation-tendency 2 "," precision byproduct-utilization 2 ","
      precision capacity-utilization 2 "," [region-type] of patch-here "," [resource-type] of patch-here ","
      [resource-quality] of patch-here "," precision [pollution-level] of patch-here 2 ","
      residue-generated-type "," residue-used-type "," precision reputation 2 ","
      precision network-position 3)
    file-print ""
  ]
  file-close
end

;; ============================================================================
;; Log patch data to CSV
;;
;; Records information about the environment state:
;; - Patch coordinates (pxcor, pycor)
;; - Resource information (type, quality, pollution level)
;; - Region characteristics (region type, cost to extract)
;; - Environmental parameters (carrying capacity, regeneration rate)
;; - Agent presence information
;;
;; Note: To reduce file size, only samples a subset of patches
;; ============================================================================
to log-patch-data
  if not enable-logging? [ stop ]

  if ticks = 0 [
    file-open "patch_data.csv"
    file-print "simulation_mode,tick,pxcor,pycor,resource_type,resource_quality,pollution_level,region_type,cost_to_extract,carrying_capacity,regeneration_rate,pollution_sensitivity,agent_present,agent_type"
    file-close
  ]

  file-open "patch_data.csv"
  let sample-size min list 100 (count patches)
  let sample-patches n-of sample-size patches

  ask sample-patches [
    let agent-present? "false"
    let agent-type "none"
    if any? turtles-here [
      set agent-present? "true"
      set agent-type [breed] of one-of turtles-here
    ]

    file-type (word simulation-mode "," ticks "," pxcor "," pycor "," resource-type ","
      ifelse-value (is-string? resource-quality) [resource-quality] [precision resource-quality 2] ","
      precision pollution-level 2 "," region-type "," precision cost-to-extract 2 ","
      precision carrying-capacity 2 "," precision regeneration-rate 4 ","
      precision pollution-sensitivity 2 "," agent-present? "," agent-type)
    file-print ""
  ]
  file-close
end

;; ============================================================================
;; Log global simulation metrics to CSV
;;
;; Records system-wide statistics for each tick:
;; - Resource counts (new, recycled, waste)
;; - Environmental metrics (pollution level, recycling efficiency)
;; - Economic indicators (market prices, transactions)
;; - Network statistics (density, average degree, centrality)
;; - Simulation parameters (API requests, agent counts)
;; ============================================================================
to log-global-data
  if not enable-logging? [ stop ]

  file-open "global_data.csv"
  file-type (word simulation-mode "," ticks "," total-new-resources "," total-recycled-resources ","
    total-waste "," precision global-pollution-level 2 "," precision market-price-waste 2 ","
    precision market-price-resource 2 "," total-transactions "," precision average-transaction-price 2 ","
    precision recycling-efficiency 3 "," precision waste-reduction-rate 3 ","
    precision network-density 3 "," precision average-node-degree 2 "," precision centrality-index 4 ","
    api-requests-made "," count turtles "," count recyclers "," count wastefuls)
  file-print ""
  file-close
end

;; ============================================================================
;; Log transaction data to CSV
;;
;; Records details of all trades between agents:
;; - Transaction parties (sender/receiver IDs and types)
;; - Resource transfer details (type, quality, amount, price)
;; - Transaction metrics (efficiency, date)
;;
;; Tracks both waste transfers and resource transfers separately
;; ============================================================================
;; Log transaction data to CSV
to log-transaction-data
  if not enable-logging? [ stop ]

  file-open "transaction_data.csv"

  ;; Log waste transfers
  ask waste-transfers with [transfer-date = ticks] [
    file-type (word simulation-mode "," ticks "," [who] of end1 "," [breed] of end1 ","
      [who] of end2 "," [breed] of end2 "," "waste" ","
      transfer-amount "," precision transfer-price 2 ","
      waste-type "," precision waste-quality 2 "," precision transfer-efficiency 2 ","
      transfer-date)
    file-print ""
  ]

  ;; Log resource transfers
  ask resource-transfers with [t-transfer-date = ticks] [
    file-type (word simulation-mode "," ticks "," [who] of end1 "," [breed] of end1 ","
      [who] of end2 "," [breed] of end2 "," "resource" ","
      t-transfer-amount "," precision t-transfer-price 2 ","
      t-resource-type "," precision t-resource-quality 2 "," precision t-transfer-efficiency 2 ","
      t-transfer-date)
    file-print ""
  ]
  file-close
end
;; ============================================================================
;; Log GPT conversation data to CSV
;;
;; Records the interaction between agents and GPT-4o:
;; - Agent information (ID, type, energy, wealth)
;; - Decision made by GPT
;; - Prompt sent to GPT
;; - Response received from GPT
;;
;; Only logs when use-gpt? is enabled
;; ============================================================================
to log-gpt-conversations
  if not enable-logging? or not use-gpt? [ stop ]

  file-open "gpt_data.csv"

  ;; Log the GPT conversation for each agent that used GPT this tick
  ask turtles with [length decision-history > 0] [
    py:set "agent_id" who
    let prompt_response py:runresult "get_latest_prompt_response(agent_id)"
    let latest-prompt item 0 prompt_response
    let latest-response item 1 prompt_response
    let latest-decision ""
    if length decision-history > 0 [
      set latest-decision last decision-history
    ]

    ;; Replace commas in prompt and response to prevent CSV issues
    set latest-prompt csv-safe-string latest-prompt
    set latest-response csv-safe-string latest-response

    file-type (word simulation-mode "," ticks "," who "," breed ","
               precision energy 2 "," precision wealth 2 ","
               "\"" latest-decision "\"" ","
               "\"" latest-prompt "\"" ","
               "\"" latest-response "\"")
    file-print ""
  ]

  file-close
end

;; ============================================================================
;; 11. UTILITY PROCEDURES
;; ============================================================================

;; Helper function to make strings safe for CSV
to-report csv-safe-string [input-string]
  ;; Replace quotes with double-quotes (CSV standard for escaping)
  let result replace-all input-string "\"" "\"\""
  ;; Escape newlines
  set result replace-all result "\n" " "
  report result
end

;; String replacement utility
to-report replace-all [original search replace]
  let result original
  while [position search result != false] [
    let pos position search result
    set result (word (substring result 0 pos)
                    replace
                    (substring result (pos + length search) (length result)))
  ]
  report result
end

;; Report the latest prompt sent to GPT
to-report latest-gpt-prompt
  report py:runresult "last_prompt_sent if 'last_prompt_sent' in globals() else 'No prompt sent yet'"
end

;; Report the latest response from GPT
to-report latest-gpt-response
  report py:runresult "last_gpt_response if 'last_gpt_response' in globals() else 'No response received yet'"
end

to select-agent
  if mouse-down? [
    let clicked-agent one-of turtles-on patch mouse-xcor mouse-ycor
    if clicked-agent != nobody [
      ask turtles [ set selected? false ]
      ask clicked-agent [ set selected? true ]
    ]
  ]
end

;; Add these reporter procedures for your monitors

to-report percent-new-resources
  report (count patches with [resource-type = "new"] / count patches) * 100
end

to-report percent-recycled-resources
  report (count patches with [resource-type = "recycled"] / count patches) * 100
end

to-report percent-waste-resources
  report (count patches with [resource-type = "waste"] / count patches) * 100
end

to-report avg-recycler-energy
  ifelse any? recyclers
    [ report mean [energy] of recyclers ]
    [ report 0 ]
end

to-report avg-wasteful-energy
  ifelse any? wastefuls
    [ report mean [energy] of wastefuls ]
    [ report 0 ]
end

to-report avg-recycler-wealth
  ifelse any? recyclers
    [ report mean [wealth] of recyclers ]
    [ report 0 ]
end

to-report avg-wasteful-wealth
  ifelse any? wastefuls
    [ report mean [wealth] of wastefuls ]
    [ report 0 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
187
15
506
335
-1
-1
8.9
1
10
1
1
1
0
1
1
1
-17
17
-17
17
1
1
1
ticks
30.0

BUTTON
8
22
83
55
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
125
85
158
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
1
200
176
233
num-recyclers
num-recyclers
0
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
1
240
176
273
num-wastefuls
num-wastefuls
0
50
24.0
1
1
NIL
HORIZONTAL

SWITCH
0
360
185
393
show-energy?
show-energy?
0
1
-1000

SLIDER
0
483
175
516
recycling-waste-cost
recycling-waste-cost
0
2
2.0
0.25
1
NIL
HORIZONTAL

SLIDER
0
523
175
556
resource-regeneration
resource-regeneration
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
0
276
175
309
max-stored-energy
max-stored-energy
10
100
50.0
5
1
NIL
HORIZONTAL

SWITCH
0
438
185
471
agents-seek-resources?
agents-seek-resources?
0
1
-1000

PLOT
725
17
930
167
Population
ticks
# of developers
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"recyclers" 1.0 0 -13345367 true "" "plot count recyclers"
"wastefuls" 1.0 0 -2674135 true "" "plot count wastefuls"

PLOT
516
175
721
325
Land Use
ticks
percent
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"new" 1.0 0 -10899396 true "" "plot (count patches with [ resource-type = \"new\" ]) / count patches * 100"
"recycled" 1.0 0 -13840069 true "" "plot (count patches with [ resource-type = \"recycled\" ]) / count patches * 100"
"waste" 1.0 0 -4079321 true "" "plot (count patches with [ resource-type = \"waste\" ]) / count patches * 100"

BUTTON
11
77
83
110
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
212
359
379
392
use-gpt?
use-gpt?
1
1
-1000

SWITCH
1
400
184
433
enable-logging?
enable-logging?
0
1
-1000

MONITOR
212
395
551
440
Latest GPT Prompt
latest-gpt-prompt
17
1
11

MONITOR
213
447
553
492
Latest GPT Response
latest-gpt-response
17
1
11

BUTTON
484
668
710
701
Show Selected Agent Conversation
if any? turtles with [selected?] [\n  show (word \"Agent \" [who] of one-of turtles with [selected?] \" conversation:\")\n  show (word \"Prompt: \" py:runresult (word \"get_latest_prompt_response(\" [who] of one-of turtles with [selected?] \")[0]\"))\n  show (word \"Response: \" py:runresult (word \"get_latest_prompt_response(\" [who] of one-of turtles with [selected?] \")[1]\"))\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
516
17
716
167
Agent Energy Comparison
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Recyclers" 1.0 0 -16777216 true "" "set-plot-pen-color blue plot avg-recycler-energy"
"Wastefuls" 1.0 0 -7500403 true "" "set-plot-pen-color red plot avg-wasteful-energy"

PLOT
728
175
928
325
Environmental Impact
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Global Pollution" 1.0 0 -16777216 true "" "set-plot-pen-color brown plot global-pollution-level"
"Recycling Efficiency" 1.0 0 -7500403 true "" "set-plot-pen-color green plot recycling-efficiency * 100"

MONITOR
744
415
900
460
New Resources (%)
precision percent-new-resources 1
17
1
11

MONITOR
744
462
899
507
Recycled Resources (%)
precision percent-recycled-resources 1
17
1
11

MONITOR
743
366
900
411
Waste Resources (%)
precision percent-waste-resources 1
17
1
11

MONITOR
743
509
900
554
Global Pollution Level
precision global-pollution-level 1
17
1
11

MONITOR
583
369
731
414
Market Price: Waste
precision market-price-waste 2
17
1
11

MONITOR
584
421
731
466
Market Price: Resources
precision market-price-resource 2
17
1
11

SWITCH
487
705
656
738
use-simple-prompts?
use-simple-prompts?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This NetLogo model simulates resource management behaviors between two types of agents, recyclers and wastefuls, who interact with a dynamic environment. Agent decisions are influenced by GPT-4o integration to enable more adaptive behavior. The model demonstrates emergent phenomena such as resource depletion, environmental regeneration, and agent survival dynamics. While partially related to industrial symbiosis concepts through its focus on recycling and resource sustainability, the model does not yet incorporate direct waste-to-resource exchanges characteristic of true industrial symbiosis networks. Future extensions could build towards this.
## HOW IT WORKS

The environment consists of a grid of cells, each of which may be in three discrete states: new (shown as green), recycled (shown as lime green), or waste (shown as yellow).  The cells are all initially in the "new" state.

There are two types of people agents - recyclers and wastefuls.  All agents have a property called "energy", which they collect from the environment.  All agents start with half of the maximum possible stored energy (defined by the MAX-STORED-ENERGY slider).  If an agent runs out of energy, they disappear.  This energy might be loosely construed as money or other economic resources, and when an agent runs out of funds, they are no longer a player in the land development game.

Each time step (tick) agents first process the cell they are on, and then move to one of the eight neighboring cells.  The movement may be random, or the agent may be more intelligent about seeking resources (if the PEOPLE-SEEK-RESOURCES? switch is turned on).

Wastefuls always totally exploit the cell they are processing, taking all the energy possible from the resource, and leaving the cell as "waste".  They gain 4 energy from "new" cells, and 2 energy from "recycled" cells, and nothing from "waste" cells.

Recyclers are conscientious, and only use half of the available resources in the cell, allowing the cell to rejuvenate the resources.  Thus, "new" cells stay "new" after being processed, but the recycler only gains 2 energy.  Recyclers also only take half (1 energy) from "recycled" cells, leaving the cell still in a recycled state.  When a recycler encounters a "waste" cell, they take the effort to recycle it, but this actually costs them energy (controlled by the RECYCLING-WASTE-COST slider), rather than gaining them anything.

Additionally, resources are randomly regenerated in the environment (at a rate controlled by the RESOURCE-REGENERATION slider).  This process causes cells change back into the "new" state.  Cells in the "recycled" state are five times more likely to change back to the new state than those in the "waste" state.  Although the factor of five is arbitrary, it is logical that squares that have been exploited/wasted are slower to regenerate.

## HOW TO USE IT

Press the SETUP button to initialize the world.  All cells are set to the "new" state, and recyclers and wastefuls are placed on random cells.

Press the GO button to run the model.  Press GO ONCE to run a single time step (tick).

Use the NUM-RECYCLERS and NUM-WASTEFULS sliders to control the initial populations of recyclers and wastefuls.

The MAX-STORED-ENERGY slider determines the maximum amount of energy that an agent can store up.  If processing a cell would cause the agent to have more than this maximum amount of energy, the agent does not process the cell.

The RECYCLING-WASTE-COST slider determines how much energy a recycler loses when it turns a "waste" cell into a "recycled" cell.

The RESOURCE-REGENERATION controls the rate at which the environment naturally regenerates resources.  A value of 0 means that the environment does not regenerate, and a value of 100 means that the environment regenerates fairly quickly.

If the AGENTS-SEEK-RESOURCES? switch is ON, then agents look at the eight neighboring cells, and first try to move to a "new" cell.  If none exists, they try to move to a "recycled" cell.  If none exists, then they move to a random cell.  If AGENTS-SEEK-RESOURCES? is switched OFF, then agents always move to a random neighboring cell.

If SHOW-ENERGY? is switched ON, then the energy for each individual agent is overlaid on the view.

The current number of recyclers and number of wastefuls are shown in the "RECYCLERS (BLUE)" and "WASTEFULS (RED)" monitors.

The populations over time are plotted in the POPULATION plot.

The "LAND USE" plot records the percentage of the cells that are in each state: new, recycled, and waste.

## THINGS TO NOTICE

In this model there is a notion of carrying-capacity.  That is, how many agents can the environment support in a relatively stable manner?  The answer depends on which type of agent is being discussed.  In this model the environment can support an arbitrarily large number of recyclers without any difficulty.  However, there is a limit on the number of wastefuls that the environment can support.  The carrying-capacity of wastefuls is dependent on several factors, particularly the RESOURCE-REGENERATION parameter, and the number of recycler agents that are in the world.

## THINGS TO TRY

Set MAX-STORED-ENERGY to 50, RECYCLING-WASTE-COST to 0.5, and RESOURCE-REGENERATION to 25.  Run the model with 25 recyclers and 25 wastefuls for 10,000 ticks.  How many of each type survived?  Now run it again for 10,000 ticks, this time with 50 recyclers and 25 wastefuls.  How many of each survived?

Try running the model with no recyclers, and 50 wastefuls.  Look at the LAND USE plot.  The cells all start as "new", but as time passes, the number of "waste" cells increases and passes the number of "new" cells, rising as high as perhaps 75% of the land use.  After this peak, the number of "waste" cells falls, until it is back down below 25% again.  Look at this plot in comparison to the POPULATION plot above it -- how do the two relate to each other?

## EXTENDING THE MODEL

The MAX-STORED-ENERGY constraint exists because without a cap on the amount of energy agents can store, it generally gave the wastefuls too strong an advantage in the world.  They would soak up vast quantities of energy (they acquire energy at a rate that is twice that of the recyclers), and then the recyclers would die off before the wastefuls had expended their reserves.  See if you can find another way to keep the model somewhat in balance, instead of having a MAX-STORED-ENERGY cap.

## NETLOGO FEATURES

The SHOW-ENERGY? feature of this model takes advantage of the fact that every turtle (and every patch) in NetLogo has a "label" property.  This means that you can assign some text to be displayed next to a turtle.  In this particular case, we show the energy level with the code:  ASK TURTLES [ SET LABEL (ROUND ENERGY) ]

This first rounds the energy to the nearest whole number (so that we don't get long labels like "48.25"), and then sets each turtle's label to be the result.

## RELATED MODELS

This model is related to all of the other models in the "Urban Suite".

An early version of this model was inspired and based on the Cooperation model in the NetLogo models library.  The Cooperation model discusses how cooperation might have arisen in the course of biological evolution.

## CREDITS AND REFERENCES

The original version of this model was developed during the Sprawl/Swarm Class at Illinois Institute of Technology in Fall 2006 under the supervision of Sarah Dunn and Martin Felsen, by the following students: Anita Phetkhamphou and Tidza Causevic .  See http://www.sprawlcity.us/ for more information about this course.

Further modifications and refinements were made by members of the Center for Connected Learning and Computer-Based Modeling before releasing it as an Urban Suite model.

The Urban Suite models were developed as part of the Procedural Modeling of Cities project, under the sponsorship of NSF ITR award 0326542, Electronic Arts & Maxis.

Please see the project web site ( http://ccl.northwestern.edu/cities/ ) for more information.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Felsen, M. and Wilensky, U. (2007).  NetLogo Urban Suite - Recycling model.  http://ccl.northwestern.edu/netlogo/models/UrbanSuite-Recycling.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2007 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2007 Cite: Felsen, M. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
