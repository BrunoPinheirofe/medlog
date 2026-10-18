import 'package:material_ui/material_ui.dart';

import '../domain/estoque_dose_calculator.dart';
import '../domain/schedule_calculator.dart';
import '../models/medicamento.dart';
import '../repositories/medicamento_repository.dart';
import 'cadastro_medicamento_page.dart';
import 'modals/edicao_rapida_modals.dart';

/// Exibe o popup de confirmação antes de excluir um medicamento.
Future<bool> confirmarExclusaoMedicamento(
  BuildContext context,
  Medicamento medicamento,
) async {
  final bool? confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Remover ${medicamento.nome}?'),
      content: const Text(
        'O medicamento e seus horários serão removidos. '
        'Você ainda poderá desfazer logo após confirmar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}

/// Página de exibição detalhada de um [Medicamento], com opções de editar e excluir.
/// Quando o usuário confirma a exclusão nesta tela, faz pop retornando o [Medicamento]
/// a ser removido pela tela de listagem.
class DetalheMedicamentoPage extends StatefulWidget {
  const DetalheMedicamentoPage({
    super.key,
    required this.medicamento,
    this.repository,
  });

  final Medicamento medicamento;
  final MedicamentoRepository? repository;

  @override
  State<DetalheMedicamentoPage> createState() => _DetalheMedicamentoPageState();
}

class _DetalheMedicamentoPageState extends State<DetalheMedicamentoPage> {
  late Medicamento _medicamento;

  @override
  void initState() {
    super.initState();
    _medicamento = widget.medicamento;
  }

  Future<void> _editarMedicamento() async {
    final atualizado = await Navigator.of(context).push<Medicamento>(
      MaterialPageRoute(
        builder: (_) => CadastroMedicamentoPage(
          medicamentoInicial: _medicamento,
          repository: widget.repository,
        ),
        fullscreenDialog: true,
      ),
    );
    if (atualizado != null && mounted) {
      setState(() {
        _medicamento = atualizado;
      });
    }
  }

  void _aplicarResultadoModal(Medicamento? atualizado) {
    if (atualizado != null && mounted) {
      setState(() {
        _medicamento = atualizado;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Medicamento atualizado com sucesso!'),
          ),
        );
    }
  }

  Future<void> _editarRapidoDose() async {
    final atualizado = await mostrarModalEditarDose(
      context,
      medicamento: _medicamento,
      repository: widget.repository,
    );
    _aplicarResultadoModal(atualizado);
  }

  Future<void> _editarRapidoHorarios() async {
    final atualizado = await mostrarModalEditarHorarios(
      context,
      medicamento: _medicamento,
      repository: widget.repository,
    );
    _aplicarResultadoModal(atualizado);
  }

  Future<void> _editarRapidoEstoque() async {
    final atualizado = await mostrarModalEditarEstoque(
      context,
      medicamento: _medicamento,
      repository: widget.repository,
    );
    _aplicarResultadoModal(atualizado);
  }

  Future<void> _editarRapidoInstrucoes() async {
    final atualizado = await mostrarModalEditarInstrucoes(
      context,
      medicamento: _medicamento,
      repository: widget.repository,
    );
    _aplicarResultadoModal(atualizado);
  }

  Future<void> _excluirMedicamento() async {
    final confirmado = await confirmarExclusaoMedicamento(context, _medicamento);
    if (confirmado && mounted) {
      Navigator.of(context).pop(_medicamento);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cor = _medicamento.corHex != null
        ? Color(_medicamento.corHex!)
        : theme.colorScheme.primary;
    final estoqueBaixo = _medicamento.estoqueAtual <= _medicamento.estoqueMinimo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Medicamento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar medicamento',
            onPressed: _editarMedicamento,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            tooltip: 'Remover medicamento',
            onPressed: _excluirMedicamento,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabeçalho principal
          Card(
            elevation: 0,
            color: cor.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cor.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cor.withValues(alpha: 0.2),
                    foregroundColor: cor,
                    child: Icon(_medicamento.forma.icon, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _medicamento.nome,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (_medicamento.descricaoDose.isNotEmpty)
                              _medicamento.descricaoDose,
                            _medicamento.forma.label,
                          ].join(' • '),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('btn_editar_rapido_dose'),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar dose',
                    onPressed: _editarRapidoDose,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Posologia e Duração
          _SecaoInfoCard(
            icone: Icons.repeat,
            titulo: 'Frequência e Duração',
            children: [
              _LinhaDetalhe(
                rotulo: 'Frequência',
                valor: _medicamento.frequencia.label,
              ),
              if (_medicamento.frequencia == Frequencia.intervaloHoras &&
                  _medicamento.intervaloHoras != null)
                _LinhaDetalhe(
                  rotulo: 'Intervalo',
                  valor: 'A cada ${_medicamento.intervaloHoras} horas',
                ),
              if (_medicamento.dataInicio != null)
                _LinhaDetalhe(
                  rotulo: 'Início do tratamento',
                  valor: _formatarDataDetalhe(_medicamento.dataInicio!),
                ),
              _LinhaDetalhe(
                rotulo: 'Tratamento',
                valor: _medicamento.usoContinuo
                    ? 'Uso contínuo'
                    : 'Temporário (${_medicamento.duracaoDias ?? 7} dias)',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Seção: Horários
          _SecaoInfoCard(
            icone: Icons.access_time,
            titulo: 'Horários das Doses',
            editButtonKey: const Key('btn_editar_rapido_horarios'),
            editTooltip: 'Editar horários',
            onEdit: _editarRapidoHorarios,
            children: [
              if (_medicamento.frequencia == Frequencia.quandoNecessario)
                Text(
                  'Uso sob demanda (SOS) — sem horários fixos.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else if (_medicamento.horarios.isEmpty)
                Text(
                  'Nenhum horário configurado.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _medicamento.horarios.map((h) {
                    return Chip(
                      avatar: Icon(Icons.alarm, size: 16, color: cor),
                      label: Text(
                        ScheduleCalculator.formatar(h),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Seção: Estoque
          _SecaoInfoCard(
            icone: Icons.inventory_2_outlined,
            titulo: 'Controle de Estoque',
            editButtonKey: const Key('btn_editar_rapido_estoque'),
            editTooltip: 'Editar estoque',
            onEdit: _editarRapidoEstoque,
            children: [
              _LinhaDetalhe(
                rotulo: 'Estoque atual',
                valor: '${formatarEstoque(_medicamento.estoqueAtual)} un.',
              ),
              _LinhaDetalhe(
                rotulo: 'Alerta mínimo',
                valor: '${_medicamento.estoqueMinimo} un.',
              ),
              if (estoqueBaixo) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estoque baixo! Considere repor este medicamento.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Seção: Instruções adicionais
          _SecaoInfoCard(
            icone: Icons.notes_outlined,
            titulo: 'Instruções e Informações Adicionais',
            editButtonKey: const Key('btn_editar_rapido_instrucoes'),
            editTooltip: 'Editar instruções',
            onEdit: _editarRapidoInstrucoes,
            children: [
              Text(
                (_medicamento.instrucoes != null &&
                        _medicamento.instrucoes!.trim().isNotEmpty)
                    ? _medicamento.instrucoes!
                    : 'Nenhuma instrução especial cadastrada.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: (_medicamento.instrucoes != null &&
                          _medicamento.instrucoes!.trim().isNotEmpty)
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecaoInfoCard extends StatelessWidget {
  const _SecaoInfoCard({
    required this.icone,
    required this.titulo,
    required this.children,
    this.onEdit,
    this.editTooltip,
    this.editButtonKey,
  });

  final IconData icone;
  final String titulo;
  final List<Widget> children;
  final VoidCallback? onEdit;
  final String? editTooltip;
  final Key? editButtonKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    key: editButtonKey,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: editTooltip ?? 'Editar',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                  ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LinhaDetalhe extends StatelessWidget {
  const _LinhaDetalhe({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rotulo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            valor,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatarDataDetalhe(DateTime data) {
  final d = data.day.toString().padLeft(2, '0');
  final m = data.month.toString().padLeft(2, '0');
  final y = data.year.toString().padLeft(4, '0');
  return '$d/$m/$y';
}
