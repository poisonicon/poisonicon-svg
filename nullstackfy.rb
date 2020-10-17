require 'fileutils'

icon_template = '// -----------------------------------------------------
// This file is generated by a script. DO NOT CHANGE IT!
// -----------------------------------------------------
import Nullstack from "nullstack";
export default ({width, height, length, title, rotation, animation, speed, class: klass, color = "currentColor"}) => {
  const transform = rotation ? `rotate(${rotation})` : false;
  const duration = {slow: "1.5s", fast: "0.5s"}[speed] || "1.0s";
  return (
    <svg width={width} height={height} transform={transform} class={klass} viewBox="0 0 512 512">
      {title && <title>{title}</title>}
      {animation === "spin" && <animateTransform attributeType="xml" attributeName="transform" type="rotate" from="360 0 0" to="0 0 0" dur={duration} additive="sum" repeatCount="indefinite" />}
      {{SVG}}
    </svg>
  )
}'

index_template = '// -----------------------------------------------------
// This file is generated by a script. DO NOT CHANGE IT!
// -----------------------------------------------------
import Nullstack from "nullstack";
{{IMPORTS}}
function pickIcon(name, type) {
  {{PICKS}}
  return false;
}
export default ({name, type="fill", width, height, length, color, title, rotation, animation, speed, class: klass}) => {
  const Icon = pickIcon(name, type);  
  return <Icon width={width} height={height} length={length} color={color} title={title} animation={animation} speed={speed} rotation={rotation} class={klass} />
}'

names = []

Dir.glob("**/*.svg").each do |filename|
  next if filename == '.' or filename == '..' or filename.count("/") > 1
  content = File.read(filename)
  name, type = filename.split('/')
  type = type.split('.')[0]
  names.push(name)
  puts "WARNING: #{filename} is missing background #f0f" unless content.match("#f0f")
  paths = content.split(">").select do |fragment|
    !fragment.match("#f0f") && !fragment.match("</") && !fragment.match("<title") && !fragment.match("<svg")
  end
  paths = paths.map do |path|
    "#{path}>"
  end
  paths = paths.join("\n      ")
  svg = icon_template.gsub('{{SVG}}', paths)
  puts "WARNING: #{filename} is missing stroke-width" if type == 'stroke' && !svg.match('stroke-width="20"')
  svg = svg.gsub('stroke-width="20"', 'stroke-width={length || 20}')
  puts "WARNING: #{filename} is missing color #0fa" if !svg.match("#0fa")
  svg = svg.gsub('"#0fa"', '{color}')
  target_folder = '../poisonicon/' + name
  target_file = target_folder + '/' + type + '.njs'
  Dir.mkdir(target_folder) unless File.exists?(target_folder)
  File.write(target_file, svg)
end

imports = []
picks = []

names.uniq.each do |name|
  name_constant = name.split('-').collect(&:capitalize).join
  ['stroke', 'fill'].each do |type|
    type_constant = type.capitalize
    imports.push("import #{name_constant}#{type_constant} from './#{name}/#{type}';")
    picks.push("if(name === '#{name}' && type === '#{type}') return #{name_constant}#{type_constant};")
  end
end

index = index_template.gsub('{{IMPORTS}}', imports.join("\n"))
index = index.gsub('{{PICKS}}', picks.join("\n  "))

File.write('../poisonicon/index.njs', index)